//! 配置变量与配置文件的结构。

use crate::jfsp::{serialize_sorted_map, types::Type};
use anyhow::{Result, bail};
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;
use std::collections::HashMap;

/// 配置变量：可由用户更改的变量。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    /// 是否自动跟随：跟随的依赖按名字去重，否则用 `父/名字` 隔离。
    #[serde(default = "default_auto_follow")]
    pub auto_follow: bool,

    /// 默认值。锁定时未找到的值自动回退到此表中查找；输入显式声明的同名参数
    /// 优先。字段缺省时为 `{hashType: sha256}`，在配置里给出同名键即可覆盖。
    #[serde(
        default = "default_defaults",
        deserialize_with = "deserialize_defaults",
        serialize_with = "serialize_sorted_map"
    )]
    pub defaults: HashMap<String, String>,

    /// 可选的额外类型数据，覆盖同名内置类型
    #[serde(default, serialize_with = "serialize_sorted_map")]
    pub types: HashMap<String, Type>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            auto_follow: default_auto_follow(),
            defaults: default_defaults(),
            types: HashMap::new(),
        }
    }
}

fn default_auto_follow() -> bool {
    true
}

fn default_defaults() -> HashMap<String, String> {
    let mut defaults: HashMap<String, String> = HashMap::new();
    defaults.insert("hashType".to_owned(), "sha256".to_owned());
    defaults
}

/// 反序列化 `Config::defaults`：先放入内置默认值，再用文件中的值覆盖。
///
/// 逐项转换而不是要求整表都是字符串：nix 配置很自然地会写 `false` 或数字。
fn deserialize_defaults<'de, D>(
    deserializer: D,
) -> Result<HashMap<String, String>, D::Error>
where
    D: Deserializer<'de>,
{
    let parsed = HashMap::<String, Value>::deserialize(deserializer)?;
    let mut defaults = default_defaults();
    for (key, value) in parsed {
        let text = scalar_to_string(&value).map_err(|err| {
            serde::de::Error::custom(format!(
                "config.defaults 的 '{key}' 不合法：{err:#}"
            ))
        })?;
        defaults.insert(key, text);
    }
    Ok(defaults)
}

/// 把配置里的标量值转换为字符串。
///
/// 结构（attrset/list）无法有意义地当作字符串，直接报错。
pub(super) fn scalar_to_string(value: &Value) -> Result<String> {
    match value {
        Value::String(text) => Ok(text.clone()),
        Value::Bool(flag) => Ok(flag.to_string()),
        Value::Number(number) => Ok(number.to_string()),
        other => {
            bail!("必须是字符串、布尔或数字，实际为 {other}")
        },
    }
}

/// 配置文件求值结果。
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigFile {
    /// 声明的输入：名称 -> 声明（必须含 `ftype`，其余为类型参数）
    #[serde(default)]
    pub inputs: HashMap<String, HashMap<String, Value>>,

    /// 可选的配置覆盖（写入锁文件的 `config`）
    #[serde(default)]
    pub config: Option<Config>,
}

#[cfg(test)]
mod tests;
