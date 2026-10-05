//! 本次运行要使用的类型数据。

use super::Lock;
use crate::jfsp::{inputs::Config, types::Type};
use log::warn;
use std::collections::HashMap;

/// 类型数据解析结果。
#[derive(Debug)]
pub struct Types {
    /// 本次运行使用的类型表：`config.types` -> 旧类型 -> 内置类型
    pub current: HashMap<String, Type>,
    /// 当前程序内置的类型数据（写锁文件时按需取用）
    pub builtin: HashMap<String, Type>,
    /// 保留下来的旧类型定义（写入 `Builtin::types_bak`）
    pub bak: HashMap<String, Type>,
    /// 旧锁文件当初生效的类型表，用于判断类型定义是否变化
    pub previous: HashMap<String, Type>,
}

/// 解析本次运行要使用的类型数据。
///
/// 优先级为 `config.types` -> 旧类型 -> 内置类型。旧锁文件用过的类型定义如果
/// 与当前内置类型不同（被改过或删除），就保留到 [`Types::bak`] 并继续按它
/// 解析，同时告警；想迁移到新定义，在 `config.types` 里覆盖同名类型即可。
pub fn resolve_types(
    builtin: &HashMap<String, Type>,
    old: Option<&Lock>,
    config: &Config,
) -> Types {
    let empty = HashMap::new();
    let old_data = old.map_or(&empty, |lock| &lock.builtin.types_data);
    let old_bak = old.map_or(&empty, |lock| &lock.builtin.types_bak);
    let old_config = old.map_or(&empty, |lock| &lock.config.types);

    let bak = legacy_types(builtin, old_data, old_bak, &config.types);
    for name in bak.keys() {
        if builtin.contains_key(name) {
            warn!(
                "内置类型 '{name}' 已修改，继续沿用锁文件里保留的定义（typesBak）；如需迁移请在 config.types 里覆盖"
            );
        } else {
            warn!(
                "内置类型 '{name}' 已被移除，继续沿用锁文件里保留的定义（typesBak）"
            );
        }
    }

    Types {
        current: merge_types(&[builtin, &bak, &config.types]),
        previous: merge_types(&[old_data, old_bak, old_config]),
        builtin: builtin.clone(),
        bak,
    }
}

/// 计算需要保留的旧类型定义。
///
/// 取旧锁文件用过的类型表（`types_bak` 优先于 `types_data`）中，与当前内置
/// 类型不同、且没有被 `config.types` 覆盖的部分。
fn legacy_types(
    builtin: &HashMap<String, Type>,
    old_data: &HashMap<String, Type>,
    old_bak: &HashMap<String, Type>,
    config: &HashMap<String, Type>,
) -> HashMap<String, Type> {
    merge_types(&[old_data, old_bak])
        .into_iter()
        .filter(|(name, btype)| {
            !config.contains_key(name) && builtin.get(name) != Some(btype)
        })
        .collect()
}

/// 按优先级合并类型表：靠后的层覆盖靠前的层。
fn merge_types(layers: &[&HashMap<String, Type>]) -> HashMap<String, Type> {
    let mut merged = HashMap::new();
    for layer in layers {
        merged.extend(
            layer
                .iter()
                .map(|(name, btype)| (name.clone(), btype.clone())),
        );
    }
    merged
}

#[cfg(test)]
mod tests;
