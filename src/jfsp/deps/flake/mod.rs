//! 解析 `flake.lock`：从 root 出发遍历节点图，把锁定信息复制出来。

use super::{NamedDep, name};
use crate::jfsp::locked::ItemDep;
use anyhow::{Context, Result, bail};
use log::warn;
use serde::Deserialize;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;

#[cfg(test)]
mod tests;

/// 依赖图的最大深度，用来兜住异常或成环的锁文件。
const MAX_DEPTH: usize = 32;

/// 依赖条数的上限：隔离模式按路径展开，病态图可能爆炸。超了宁可报错，
/// 也不要静默写出不完整的 `deps`。
const MAX_DEPS: usize = 2048;

#[derive(Deserialize)]
struct FlakeLock {
    root: String,

    #[serde(default)]
    nodes: HashMap<String, Node>,
}

#[derive(Deserialize, Default)]
struct Node {
    /// 该节点被锁定的信息；根节点通常没有
    #[serde(default)]
    locked: Option<Value>,

    #[serde(default)]
    inputs: HashMap<String, Value>,
}

/// `inputs` 的取值。无法识别的取值会被跳过，而不是让整个文件解析失败。
enum Reference {
    /// 节点名
    Name(String),

    /// 从根节点出发的属性路径，表示跟随
    Path(Vec<String>),

    /// `flake = false` 的输入，没有可复制的锁定信息
    Disabled,
}

/// 读取并解析 flake.lock。
pub fn read(path: &Path, prefix: &str, isolate: bool) -> Result<Vec<NamedDep>> {
    let text = std::fs::read_to_string(path)
        .with_context(|| format!("无法读取 flake.lock：{}", path.display()))?;
    parse(&text, prefix, isolate)
}

fn parse(text: &str, prefix: &str, isolate: bool) -> Result<Vec<NamedDep>> {
    let lock: FlakeLock =
        serde_json::from_str(text).context("flake.lock 格式不正确")?;
    if !lock.nodes.contains_key(&lock.root) {
        bail!("flake.lock 缺少 root 节点 '{}'", lock.root);
    }

    let mut walker = Walker {
        lock: &lock,
        isolate,
        deps: Vec::new(),
        emitted: HashMap::new(),
        capped: false,
    };
    walker.walk(&lock.root, &[prefix.to_owned()], 0);

    if walker.capped {
        bail!("flake.lock 的依赖超过 {MAX_DEPS} 条，拒绝写出不完整的锁");
    }

    walker.deps.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(walker.deps)
}

/// 解析 `inputs` 的取值。
///
/// - 字符串：节点名；
/// - 数组：从根节点出发的属性路径（新版 flake.lock 表示 follows 的写法）；
/// - `{ "follows": "a/b" }`：旧版写法；
/// - `false`：`flake = false` 的输入。
fn reference_from_value(value: &Value) -> Option<Reference> {
    match value {
        Value::String(name) => Some(Reference::Name(name.clone())),
        Value::Bool(false) => Some(Reference::Disabled),
        Value::Array(parts) => parts
            .iter()
            .map(Value::as_str)
            .map(|part| part.map(str::to_owned))
            .collect::<Option<Vec<String>>>()
            .map(Reference::Path),
        Value::Object(map) => map
            .get("follows")
            .and_then(Value::as_str)
            .map(|path| Reference::Path(split_path(path))),
        _ => None,
    }
}

/// 把 `a/b` 形式的跟随路径拆成属性路径。
fn split_path(text: &str) -> Vec<String> {
    text.split('/')
        .filter(|part| !part.is_empty())
        .map(str::to_owned)
        .collect()
}

struct Walker<'a> {
    lock: &'a FlakeLock,
    isolate: bool,
    deps: Vec<NamedDep>,
    /// 跟随时已经写出的依赖，用来按名字去重
    emitted: HashMap<String, ItemDep>,
    /// 是否已经撞上条数上限
    capped: bool,
}

impl Walker<'_> {
    fn walk(&mut self, node_name: &str, path: &[String], depth: usize) {
        if depth >= MAX_DEPTH {
            warn!("flake.lock 的依赖层级过深，已停止遍历：{}", path.join("/"));
            return;
        }
        if self.deps.len() >= MAX_DEPS {
            self.capped = true;
            return;
        }

        let Some(node) = self.lock.nodes.get(node_name) else {
            warn!("flake.lock 缺少节点 '{node_name}'");
            return;
        };

        // 排序后再遍历，保证结果与 HashMap 的顺序无关
        let mut inputs: Vec<(&String, &Value)> = node.inputs.iter().collect();
        inputs.sort_by(|a, b| a.0.cmp(b.0));

        for (alias, value) in inputs {
            let Some(reference) = reference_from_value(value) else {
                warn!("flake.lock 无法识别的依赖 '{alias}'：{value}");
                continue;
            };
            if matches!(reference, Reference::Disabled) {
                continue;
            }
            let Some(target) = self.resolve(&reference, 0) else {
                warn!("flake.lock 无法解析依赖 '{alias}'");
                continue;
            };

            // 只有节点真的带着锁定信息才算一条依赖；没有锁定信息的中转节点
            // 只用来继续往下走
            if let Some(locked) = self
                .lock
                .nodes
                .get(&target)
                .and_then(|node| node.locked.as_ref())
            {
                match item_dep(locked) {
                    Some(dep) => {
                        let dep_name =
                            name(alias, &path.join("/"), self.isolate);
                        self.emit(dep_name, dep);
                    },
                    None => {
                        warn!("flake.lock 的依赖 '{alias}' 缺少 type，已跳过");
                    },
                }
            }

            let mut next = path.to_vec();
            next.push(alias.clone());
            self.walk(&target, &next, depth + 1);
        }
    }

    /// 记录一条依赖：跟随时按名字去重，保留先出现的。
    fn emit(&mut self, dep_name: String, dep: ItemDep) {
        if !self.isolate {
            if let Some(previous) = self.emitted.get(&dep_name) {
                if previous != &dep {
                    warn!("依赖 '{dep_name}' 出现不同的定义，保留先出现的");
                }
                return;
            }
            self.emitted.insert(dep_name.clone(), dep.clone());
        }
        self.deps.push(NamedDep {
            name: dep_name,
            dep,
        });
    }

    /// 把引用解析为节点名。
    fn resolve(&self, reference: &Reference, depth: usize) -> Option<String> {
        if depth > MAX_DEPTH {
            return None;
        }
        match reference {
            Reference::Name(target) => {
                self.lock.nodes.contains_key(target).then(|| target.clone())
            },
            Reference::Path(parts) => self.follow(parts, depth + 1),
            Reference::Disabled => None,
        }
    }

    /// 属性路径相对根节点，逐段解析。
    ///
    /// 空路径没有意义（真实 flake.lock 里出现过 `follows = ""` 导致的 `[]`），
    /// 若当成“根节点”会让遍历绕回整张图，所以直接判定为无法解析。
    fn follow(&self, path: &[String], depth: usize) -> Option<String> {
        if path.is_empty() {
            return None;
        }

        let mut current = self.lock.root.clone();
        for part in path {
            let node = self.lock.nodes.get(&current)?;
            let reference = reference_from_value(node.inputs.get(part)?)?;
            current = self.resolve(&reference, depth + 1)?;
        }
        Some(current)
    }
}

/// 直接复制节点的锁定信息；`ftype` 取节点本身的类型。
///
/// nix 的各种 fetcher 都会写出 `type`，凭空补一个名字会误导后续消费者，
/// 所以缺 `type` 的节点按无法识别处理。
fn item_dep(locked: &Value) -> Option<ItemDep> {
    Some(ItemDep {
        ftype: locked.get("type").and_then(Value::as_str)?.to_owned(),
        locked: locked.clone(),
    })
}
