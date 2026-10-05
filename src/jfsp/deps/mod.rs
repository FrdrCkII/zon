//! 依赖读取：从已锁定输入的源码目录里解析 `channels.lock` 或 `flake.lock`。
//!
//! 工具不实现完整的 flakes 功能，只把来源锁文件里的锁定信息直接复制过来。
//!
//! 命名遵循 `Tree` 的设计：自动跟随时依赖按名字去重；不跟随时用
//! `父/名字` 隔离，多层依赖会得到 `父/子/名字`。

mod channels;
mod flake;

use crate::jfsp::locked::ItemDep;
use anyhow::Result;
use log::warn;
use std::collections::HashMap;
use std::collections::hash_map::Entry;
use std::path::Path;

/// 一条依赖候选：名字 + 直接复制的锁定信息。
#[derive(Clone, Debug, PartialEq)]
pub struct NamedDep {
    pub name: String,
    pub dep: ItemDep,
}

/// 从源码目录读取依赖。
///
/// 优先 `channels.lock`，读不了再退回 `flake.lock`（“优先”不等于排他）；
/// 两者都没有就没有依赖。解析失败会向上报错：宁可失败，也不要写出一份
/// 悄悄少了依赖的锁文件。
pub fn read(dir: &Path, prefix: &str, isolate: bool) -> Result<Vec<NamedDep>> {
    let channels = dir.join("channels.lock");
    if channels.is_file() {
        match channels::read(&channels, prefix, isolate) {
            Ok(deps) => return Ok(deps),
            Err(err) => {
                warn!(
                    "忽略无法读取的依赖锁文件 {}：{err:#}",
                    channels.display()
                );
            },
        }
    }

    let flake = dir.join("flake.lock");
    if flake.is_file() {
        return flake::read(&flake, prefix, isolate);
    }

    Ok(Vec::new())
}

/// 把依赖加入表里：按名字去重，保留先出现的。
///
/// 返回 `true` 表示这个名字已经存在且定义不同；由调用方决定怎么告警，
/// 这样可以按名字汇总，而不是每条依赖都喊一声。
pub fn insert(deps: &mut HashMap<String, ItemDep>, named: NamedDep) -> bool {
    match deps.entry(named.name) {
        Entry::Occupied(entry) => entry.get() != &named.dep,
        Entry::Vacant(entry) => {
            entry.insert(named.dep);
            false
        },
    }
}

/// 按命名策略生成依赖名：不跟随时用 `父/名字` 隔离。
fn name(raw: &str, prefix: &str, isolate: bool) -> String {
    if isolate {
        format!("{prefix}/{raw}")
    } else {
        raw.to_owned()
    }
}

#[cfg(test)]
mod tests;
