mod clap;
mod json;
mod pipe;

use crate::clap::{Parsed, Update};
use crate::json::{
  DepValue, FlakeLock, InputItem, InputMap, InputResult, InputValue,
};
use anyhow::{Result, anyhow, bail};
use serde_json::Value;
use std::collections::{BTreeMap, HashMap};
use std::path::PathBuf;
use std::{env, sync::Arc};
use tokio::spawn;

type LockedMap = HashMap<String, LockedItem>;
type LockedItem = HashMap<String, String>;

const TYPES: &str = include_str!("type.nix");

pub fn run(args: Vec<String>) -> Result<()> {
  let parsed = clap::parse(args)?;

  tokio::runtime::Builder::new_multi_thread()
    .enable_all()
    .build()?
    .block_on(async_run(parsed))
}

async fn async_run(parsed: Parsed) -> Result<()> {
  let args = Arc::new(parsed);
  let locked_path = args.config.with_extension("lock");

  // ---- 1. 解析输入 / 读取旧锁 ----
  let (inputs, locked) = {
    let inputs = {
      let config = &args.config.to_string_lossy();
      let config_expr = serde_json::to_string(config.as_ref())?;
      let nix_expr =
        format!(r#"let types = {TYPES}; in types (import {config_expr})"#);

      let nix_child = tokio::process::Command::new("nix")
        .arg("eval")
        .arg("--extra-experimental-features")
        .arg("nix-command")
        .arg("--impure")
        .arg("--json")
        .arg("--no-pretty")
        .arg("--expr")
        .arg(&nix_expr)
        .kill_on_drop(true)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .spawn()?
        .wait_with_output()
        .await?;

      if nix_child.status.success() {
        let stdout = std::str::from_utf8(&nix_child.stdout)?
          .trim()
          .trim_matches('"');
        InputValue::serde(&stdout)?
      } else {
        bail!("nix cannot evaluate the config file!")
      }
    };
    let locked: LockedMap = if locked_path.exists()
      && let Ok(json_str) = std::fs::read_to_string(&locked_path)
      && let Ok(locked) = serde_json::from_str(&json_str)
    {
      locked
    } else {
      HashMap::new()
    };

    (inputs, Arc::new(locked))
  };

  // ---- 2. 构建运行时环境 ----
  let env_path = build_env_path(&inputs).await?;

  // ---- 3. 锁定顶层输入 ----
  let mut results: BTreeMap<String, InputResult> = BTreeMap::new();
  {
    let mut handles = Vec::new();
    for (name, input) in &inputs {
      let args = args.clone();
      let locked = locked.clone();
      let env_path = env_path.clone();
      let name = name.clone();
      let input = input.clone();
      handles.push(spawn(async move {
        let (_, meta) =
          tasks_main(args, locked, env_path, name.clone(), input.clone())
            .await?;
        Ok::<_, anyhow::Error>((name, meta))
      }));
    }
    for handle in handles {
      let (name, meta) = handle.await??;
      results.insert(
        name,
        InputResult {
          meta: meta.into_iter().collect(),
          deps: BTreeMap::new(),
        },
      );
    }
  }

  // ---- 4. 递归解析 flakes 依赖 ----
  if args.recursion {
    resolve_flake_deps(&args, &locked, &env_path, &inputs, &mut results)
      .await?;
  }

  // ---- 5. 输出 ----
  let json_str = serde_json::to_string_pretty(&results)?;
  std::fs::write(locked_path, format!("{json_str}\n"))?;

  Ok(())
}

/// 和之前一样的包构建，但改用 `pathsToLink = [ "/bin" ]` 避免 `ignoreCollisions`。
async fn build_env_path(inputs: &InputMap) -> Result<Arc<String>> {
  let packages = json::get_packages(inputs)?;
  let packages_expr = packages
    .iter()
    .map(|pkg| format!("pkgs.{pkg}"))
    .collect::<Vec<String>>()
    .join(" ");
  let nix_expr = format!(
    r#"let pkgs = import <nixpkgs> {{}};
           in pkgs.buildEnv {{
                name = "nixlock-pkgs";
                paths = [ {packages_expr} ];
                pathsToLink = [ "/bin" ];
              }}"#
  );

  let nix_child = tokio::process::Command::new("nix")
    .arg("build")
    .arg("--extra-experimental-features")
    .arg("nix-command")
    .arg("--impure")
    .arg("--no-link")
    .arg("--json")
    .arg("--no-pretty")
    .arg("--expr")
    .arg(&nix_expr)
    .kill_on_drop(true)
    .stdin(std::process::Stdio::null())
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::inherit())
    .spawn()?
    .wait_with_output()
    .await?;

  if !nix_child.status.success() {
    bail!("nix cannot build these packages!\n{nix_expr}")
  }

  let stdout = std::str::from_utf8(&nix_child.stdout)?;
  let stdout_json: Vec<Value> = serde_json::from_str(stdout)?;
  let out = stdout_json
    .get(0)
    .and_then(|item| item.get("outputs"))
    .and_then(|outputs| outputs.get("out"))
    .and_then(|out| out.as_str())
    .ok_or_else(|| anyhow!("missing `[0].outputs.out`"))?
    .to_owned();

  let current = env::var("PATH").unwrap_or_default();
  Ok(Arc::new(format!("{out}/bin:{current}")))
}

/// 递归解析每个顶层输入的 flake.lock，填充 `deps`。
///
/// 判定一个输入是否为 flake 的规则：
/// - 其 meta 中存在 `storePath` 字段（由 type.nix 中对应的解包类型提供）；
/// - `storePath/flake.lock` 存在且可解析。
///
/// 每个依赖的处理：
/// - 若 `--follow` 启用且依赖名与某个顶层输入同名，记录 `"parent/name"` 字符串；
/// - 否则在 flake.lock 中查对应节点，把它的 `locked` 展平作为 `meta`，
///   不再进一步递归（避免在网络与求值上无限展开）。
async fn resolve_flake_deps(
  args: &Parsed,
  _locked: &Arc<LockedMap>,
  _env_path: &Arc<String>,
  inputs: &InputMap,
  results: &mut BTreeMap<String, InputResult>,
) -> Result<()> {
  // 收集所有拥有 storePath 的顶层输入
  let mut queue: Vec<(String, PathBuf)> = results
    .iter()
    .filter_map(|(name, res)| {
      res
        .meta
        .get("storePath")
        .map(|sp| (name.clone(), PathBuf::from(sp)))
    })
    .collect();

  while let Some((parent, store_path)) = queue.pop() {
    let lock_path = store_path.join("flake.lock");
    if !lock_path.exists() {
      continue;
    }

    let flake_lock = match FlakeLock::parse(&lock_path) {
      Ok(l) => l,
      Err(_) => continue,
    };

    let mut dep_map: BTreeMap<String, DepValue> = BTreeMap::new();

    for (dep_name, dep_ref) in flake_lock.direct_deps() {
      // 自动跟随：依赖名与某个顶层输入同名
      if args.follow && inputs.contains_key(&dep_name) {
        dep_map
          .insert(dep_name, DepValue::Followed(format!("{parent}/{dep_ref}")));
        continue;
      }

      let Some(node) = flake_lock.nodes.get(&dep_ref) else {
        continue;
      };

      // 有 locked：记录关键字段作为 meta
      // 无 locked：这是一个 follow 引用
      match &node.locked {
        Some(locked) => {
          let meta = json::extract_locked_fields(locked);
          dep_map.insert(
            dep_name,
            DepValue::Input(InputResult {
              meta,
              deps: BTreeMap::new(),
            }),
          );
        },
        None => {
          dep_map.insert(
            dep_name,
            DepValue::Followed(format!("{parent}/{dep_ref}")),
          );
        },
      }
    }

    if let Some(res) = results.get_mut(&parent) {
      res.deps = dep_map;
    }
  }

  Ok(())
}

// ---- tasks_main 保持不变，签名不变 ----
async fn tasks_main(
  args: Arc<Parsed>,
  locked: Arc<LockedMap>,
  env_path: Arc<String>,
  name: String,
  input: InputItem,
) -> Result<(String, HashMap<String, String>)> {
  let order = json::resolve_dependency_order(&input)?;
  let need_update = match &args.update {
    Update::Lock => false,
    Update::List(up) => up.is_empty() || up.contains(&name),
  };

  let empty = HashMap::new();
  let locked = locked.get(&name).unwrap_or(&empty);

  let mut result: HashMap<String, String> = HashMap::new();
  for (i, list) in order.into_iter().enumerate() {
    for item in list {
      let value = input.get(&item).ok_or(anyhow!(""))?;

      if i == 0 {
        if let InputValue::String(value_str) = value {
          result.insert(item, value_str.to_owned());
        } else {
          bail!("The first-level node '{}' must be a string type", item);
        }
      } else {
        let deps = value.get_deps();
        let substitute = value.substitute_deps(&result);

        match substitute {
          InputValue::String(value_str) => {
            result.insert(item, value_str.to_owned());
          },

          InputValue::Commands {
            commands, update, ..
          } => {
            let deps_change = deps.into_iter().any(|dep| {
              if let Some(lock) = locked.get(&dep)
                && let Some(new) = result.get(&dep)
              {
                lock != new
              } else {
                true
              }
            });

            if !(deps_change || (update && need_update))
              && let Some(value) = locked.get(&item)
            {
              result.insert(item, value.to_owned());
            } else {
              let run = pipe::pipeline(commands, &env_path).await?;
              result.insert(item, run);
            }
          },
        }
      }
    }
  }

  Ok((name, result))
}
