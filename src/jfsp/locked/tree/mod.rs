//! 锁文件的结构定义。
//!
//! `tree` 把 `top`（声明的输入）与 `deps`（引入的依赖）分开：自动跟随时，
//! 依赖通过名字自然去重；不跟随时，名字被写成 `父/名字` 以隔离。

use crate::jfsp::{inputs::Config, serialize_sorted_map, types::Type};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

pub const VER_FILE: u8 = 1;
pub const VER_LOCK: u8 = 1;
pub const VER_TYPE: u8 = 1;

/// 锁文件的版本号：`{锁文件格式版本}.{锁版本}.{类型数据版本}`。
pub fn version() -> String {
    format!("{VER_FILE}.{VER_LOCK}.{VER_TYPE}")
}

/// 锁文件。
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Lock {
    pub config: Config,
    pub builtin: Builtin,
    pub locked: Tree,
}

/// 内置变量：由程序自动维护的变量，不应该修改。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Builtin {
    /// 锁文件格式版本与程序内置的类型数据版本
    pub version: String,

    /// 锁文件使用过的内置类型定义，按需记录（只记用到的类型）。
    ///
    /// 下次运行拿它和当前内置类型比较：不同就说明程序改过类型定义。
    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub types_data: HashMap<String, Type>,

    /// 被保留下来的旧类型定义：内置类型改过（或被移除）而配置又没有覆盖时，
    /// 旧锁文件继续按当初的定义解析，避免用新定义重新解释旧值。
    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub types_bak: HashMap<String, Type>,
}

/// 锁定树：`top` 是声明的输入，`deps` 是引入的依赖。
#[derive(Clone, Debug, PartialEq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Tree {
    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub top: HashMap<String, ItemTop>,

    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub deps: HashMap<String, ItemDep>,
}

/// 一个已锁定的输入。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ItemTop {
    pub ftype: String,

    /// 更新分组；旧锁文件可能没有这个字段
    #[serde(default = "default_group")]
    pub group: String,

    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub locked: HashMap<String, String>,
}

fn default_group() -> String {
    crate::jfsp::inputs::DEFAULT_GROUP.to_owned()
}

/// 一条依赖：直接保存从来源锁文件里复制出来的锁定信息。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ItemDep {
    /// 来源类型：flake.lock 节点的 `type`（如 `github`），
    /// 或 channels.lock 里的 ftype
    pub ftype: String,

    /// 原样复制的锁定信息
    pub locked: Value,
}

#[cfg(test)]
mod tests;
