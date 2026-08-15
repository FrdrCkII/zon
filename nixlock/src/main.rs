mod args;
mod json;
mod runf;

use crate::args::{Args, Update};
use crate::json::{InputItem, InputValue};
use anyhow::{Result, anyhow, bail};
use serde_json::Value;
use std::{
    collections::{BTreeMap, HashMap},
    env,
    sync::Arc,
};
use tokio::spawn;

type LockedMap = HashMap<String, LockedItem>;
type LockedItem = HashMap<String, String>;

const TYPES: &str = include_str!("type.nix");

fn main() -> Result<()> {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?
        .block_on(async_main())
}

async fn async_main() -> Result<()> {
    let args = Arc::new(args::parse()?);
    let locked_path = args.config.with_extension("lock");

    // 解析输入/锁定文件
    let (inputs, locked) = {
        let inputs = {
            let nix_expr = format!(
                r#"let types = {TYPES}; in types (import {})"#,
                &args.config.to_string_lossy()
            );

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
                bail!("nix cannot evaluate this config file!\n{nix_expr}")
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

    // 从nix构建额外包
    let env_path = {
        let packages = {
            let packages = json::get_packages(&inputs)?;
            let packages_expr = packages
                .into_iter()
                .map(|pkg| format!("pkgs.{pkg}"))
                .collect::<Vec<String>>()
                .join(" ");
            let nix_expr = format!(
                r#"let pkgs = import <nixpkgs> {{}}; in pkgs.buildEnv {{ name = "nixlock-pkgs"; ignoreCollisions = true; paths = [ {packages_expr} ]; }}"#
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

            if nix_child.status.success() {
                let stdout = std::str::from_utf8(&nix_child.stdout)?;
                let stdout_json: Vec<Value> = serde_json::from_str(stdout)?;
                stdout_json
                    .get(0)
                    .and_then(|item| item.get("outputs"))
                    .and_then(|outputs| outputs.get("out"))
                    .and_then(|out| out.as_str())
                    .ok_or_else(|| anyhow!("missing `[0].outputs.out`"))?
                    .to_owned()
            } else {
                bail!("nix cannot build these packages!\n{nix_expr}")
            }
        };

        let current = env::var("PATH").unwrap_or_default();
        Arc::new(format!("{packages}/bin:{current}"))
    };

    // main
    let results = {
        let mut results: HashMap<String, HashMap<String, String>> =
            HashMap::with_capacity(inputs.len());

        let handles = inputs
            .into_iter()
            .map(|(name, input)| {
                let args = args.clone();
                let locked = locked.clone();
                let env_path = env_path.clone();
                spawn(async move {
                    let name = name.to_owned();
                    tasks_main(args, locked, env_path, name, input).await
                })
            })
            .collect::<Vec<_>>();

        for handle in handles {
            let (name, result) = handle.await??;
            results.insert(name, result);
        }

        let ordered = results
            .into_iter()
            .map(|(k, v)| (k, v.into_iter().collect::<BTreeMap<_, _>>()))
            .collect::<BTreeMap<_, _>>();

        serde_json::to_string(&ordered)?
    };

    std::fs::write(locked_path, results)?;

    Ok(())
}

async fn tasks_main(
    args: Arc<Args>,
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

    let locked = if let Some(input) = locked.get(&name) {
        input
    } else {
        &HashMap::new()
    };

    let mut result: HashMap<String, String> = HashMap::new();
    for (i, list) in order.into_iter().enumerate() {
        for item in list {
            let value = input.get(&item).ok_or(anyhow!(""))?;

            if i == 0 {
                if let InputValue::String(value_str) = value {
                    result.insert(item, value_str.to_owned());
                } else {
                    bail!("");
                }
            } else {
                let deps = value.get_deps();
                let substitute = value.substitute_deps(&result);

                match substitute {
                    InputValue::String(value_str) => {
                        result.insert(item, value_str.to_owned());
                    }

                    InputValue::Commands {
                        commands, update, ..
                    } => {
                        let deps_change = deps.into_iter().all(|dep| {
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
                            let run = runf::pipeline(commands, &env_path).await?;
                            result.insert(item, run);
                        }
                    }
                }
            }
        }
    }

    Ok((name, result))
}
