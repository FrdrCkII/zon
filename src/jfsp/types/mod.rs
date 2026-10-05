//! 类型数据：输入类型（任务模板）、任务模型与相关的解析工具。

mod builtin;
mod format;
mod order;
mod task;
mod tasks;

pub use self::builtin::builtin_types;
pub use self::task::{Action, Resolver, Task};
pub use self::tasks::{expand, expand_type};

pub(crate) use self::format::{placeholders, substitute};
pub(crate) use self::order::resolve_order;

use super::{serialize_sorted_map, serialize_sorted_set};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

/// 类型：一组按属性名索引的任务，外加命令管道需要的包。
///
/// 类型只是“快速模板”：配置里可以直接给出同样结构的类型来覆盖它，也可以把
/// 需要的属性作为输入参数写进配置文件。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Type {
    /// 命令管道需要用到的 nixpkgs 包
    #[serde(default, serialize_with = "serialize_sorted_set")]
    pub packages: HashSet<String>,

    /// 属性名 -> 任务
    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub tasks: HashMap<String, Task>,
}
