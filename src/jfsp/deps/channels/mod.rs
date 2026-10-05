//! 解析 `channels.lock`：把 `top` 与 `deps` 里的输入当作依赖复制出来。

use super::{NamedDep, name};
use crate::jfsp::locked::ItemDep;
use anyhow::{Context, Result};
use log::warn;
use serde::Deserialize;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;

/// 只取需要的部分，其他字段（config/builtin）会被忽略。
#[derive(Deserialize)]
struct ChannelsLock {
    #[serde(default)]
    locked: Locked,
}

#[derive(Deserialize, Default)]
struct Locked {
    #[serde(default)]
    top: HashMap<String, Value>,
    #[serde(default)]
    deps: HashMap<String, Value>,
}

/// 读取并解析 channels.lock。
pub fn read(path: &Path, prefix: &str, isolate: bool) -> Result<Vec<NamedDep>> {
    let text = std::fs::read_to_string(path).with_context(|| {
        format!("无法读取 channels.lock：{}", path.display())
    })?;
    parse(&text, prefix, isolate)
}

fn parse(text: &str, prefix: &str, isolate: bool) -> Result<Vec<NamedDep>> {
    let lock: ChannelsLock =
        serde_json::from_str(text).context("channels.lock 格式不正确")?;

    // 逐条转换：一条坏记录不应该带走整份文件里的其他依赖
    let mut deps = Vec::new();
    for (raw, value) in lock.locked.top.iter().chain(lock.locked.deps.iter()) {
        match dep_from_value(value) {
            Some(dep) => deps.push(NamedDep {
                name: name(raw, prefix, isolate),
                dep,
            }),
            None => {
                warn!("channels.lock 里的 '{raw}' 不是可复制的依赖，已跳过");
            },
        }
    }

    deps.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(deps)
}

/// 把 channels.lock 里的一条记录转换成依赖。
///
/// `top` 与 `deps` 的结构略有不同，这里只要求 `locked` 是对象，`ftype` 可选，
/// 其余字段原样复制。
fn dep_from_value(value: &Value) -> Option<ItemDep> {
    let object = value.as_object()?;
    let locked = object.get("locked")?;
    locked.as_object()?;

    let ftype = object
        .get("ftype")
        .and_then(Value::as_str)
        .unwrap_or("channels");

    Some(ItemDep {
        ftype: ftype.to_owned(),
        locked: locked.clone(),
    })
}

#[cfg(test)]
mod tests;
