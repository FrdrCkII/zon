//! 任务模型：字符串模板、命令管道与取值方式。

use anyhow::{Context, Result, bail};
use serde::ser::SerializeMap;
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use serde_json::Value;
use std::collections::HashMap;

/// 任务：属性值的计算方式。
///
/// 一个任务可以写出多个属性：命令管道通常用 [`Resolver::Json`] 一次取出多个
/// 键值对，这正是为了省掉重复的昂贵命令（例如 `nix store prefetch-file`）。
#[derive(Clone, Debug, PartialEq)]
pub enum Task {
    /// 布尔字面量
    Bool(bool),

    /// 字符串模板：`{key}` 会被替换为变量值，找不到时回退到 `config.defaults`
    String(String),

    /// 命令管道
    Action(Action),

    /// 尝试调用同名函数，只是一种简写的尝试；**只在运行任务时展开**，
    /// 写进锁文件时保持字符串，方便配置文件快速调用预制任务。
    Builtin(String),
}

/// 命令管道：顺序执行，前一条命令的标准输出连接后一条的标准输入。
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Action {
    /// 如何从最后一条命令的标准输出中取值；缺省为原样取用
    #[serde(default, skip_serializing_if = "Resolver::is_raw")]
    pub resolver: Resolver,

    /// 是否是纯函数：结果只取决于占位符的取值，不依赖外部状态。
    ///
    /// 例如消费 `immut`（不可变链接）的哈希计算，同名输入必然得到同名输出，
    /// 因此即使要求强制更新也可以沿用旧值。缺省为否。
    #[serde(default, skip_serializing_if = "is_false")]
    pub pure: bool,

    /// 每条命令的参数表
    pub commands: Vec<Vec<String>>,
}

/// 供 serde 省略 `pure = false` 使用。
fn is_false(value: &bool) -> bool {
    !*value
}

/// 从命令输出中取值的方式。
#[derive(Clone, Debug, PartialEq)]
pub enum Resolver {
    /// 原样取用（去掉首尾空白），写成任务名对应的属性
    Raw,

    /// 解析为 JSON 对象，按键名取出值，再用给定的名字写进锁定表。
    ///
    /// 键是 JSON 里的字段名，值是锁定表里的属性名，因此可以给同一个命令的
    /// 多个输出起自定义名字，也避免直接用 JSON 键名意外覆盖别的属性。
    Json(HashMap<String, String>),
}

impl Default for Resolver {
    fn default() -> Self {
        Self::Raw
    }
}

impl Resolver {
    /// 是否原样取用；用于在序列化时省略该字段。
    pub(crate) fn is_raw(&self) -> bool {
        matches!(self, Self::Raw)
    }

    /// 该任务会写出哪些属性。
    pub(crate) fn properties(&self, task_name: &str) -> Vec<String> {
        match self {
            Self::Raw => vec![task_name.to_owned()],
            Self::Json(keys) => keys.values().cloned().collect(),
        }
    }

    /// 从命令的标准输出中取出键值对。
    pub(crate) fn extract(
        &self,
        task_name: &str,
        output: &str,
    ) -> Result<Vec<(String, String)>> {
        let output = output.trim();
        match self {
            Self::Raw => Ok(vec![(task_name.to_owned(), output.to_owned())]),
            Self::Json(keys) => {
                let value: Value =
                    serde_json::from_str(output).with_context(|| {
                        format!("命令输出不是有效的 JSON：{output}")
                    })?;
                let Value::Object(object) = &value else {
                    bail!("命令输出不是 JSON 对象：{output}");
                };

                // JSON 里没有的键直接跳过，不做特殊处理
                Ok(keys
                    .iter()
                    .filter_map(|(key, name)| {
                        object
                            .get(key)
                            .map(|value| (name.clone(), json_text(value)))
                    })
                    .collect())
            },
        }
    }
}

/// 把 JSON 字段转成锁定表里的字符串。
fn json_text(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        other => other.to_string(),
    }
}

impl Serialize for Resolver {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            // 该字段会被 `skip_serializing_if` 省略，这里只是兜底
            Self::Raw => serializer.serialize_none(),
            Self::Json(keys) => {
                let mut sorted: Vec<(&String, &String)> = keys.iter().collect();
                sorted.sort();
                let mut map = serializer.serialize_map(Some(sorted.len()))?;
                for (key, name) in sorted {
                    map.serialize_entry(key, name)?;
                }
                map.end()
            },
        }
    }
}

impl<'de> Deserialize<'de> for Resolver {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        match Value::deserialize(deserializer)? {
            Value::Null => Ok(Self::Raw),
            Value::String(text) if text == "raw" => Ok(Self::Raw),
            Value::Object(map) => {
                // 空映射的任务永远写不出属性，属于配置错误，尽早报出来
                if map.is_empty() {
                    return Err(serde::de::Error::custom(
                        "Resolver::Json 至少要指定一个键",
                    ));
                }

                map.into_iter()
                    .map(|(key, value)| match value {
                        Value::String(name) => Ok((key, name)),
                        other => Err(serde::de::Error::custom(format!(
                            "属性名必须是字符串，实际为 {other}"
                        ))),
                    })
                    .collect::<Result<HashMap<String, String>, _>>()
                    .map(Self::Json)
            },
            other => Err(serde::de::Error::custom(format!(
                "无法识别的输出解析方式：{other}"
            ))),
        }
    }
}

impl Serialize for Task {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            Self::Bool(flag) => serializer.serialize_bool(*flag),
            Self::String(text) => serializer.serialize_str(text),
            // 内置简写写出来就是那个字符串，配置文件可以直接照着写
            Self::Builtin(name) => serializer.serialize_str(name),
            Self::Action(action) => action.serialize(serializer),
        }
    }
}

impl<'de> Deserialize<'de> for Task {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = Value::deserialize(deserializer)?;
        task_from_value(value).map_err(serde::de::Error::custom)
    }
}

/// 从 JSON 值解析任务。
///
/// 字符串既可能是模板，也可能是内置简写：只有注册过的名字才算简写。看起来
/// 像简写但没注册的名字会直接报错，避免拼错之后静默变成字面量。
fn task_from_value(value: Value) -> Result<Task, String> {
    match value {
        Value::Bool(flag) => Ok(Task::Bool(flag)),
        Value::String(text) => {
            if super::tasks::is_builtin(&text) {
                Ok(Task::Builtin(text))
            } else if super::tasks::looks_like_builtin(&text) {
                Err(format!("未知的内置任务：{text}"))
            } else {
                Ok(Task::String(text))
            }
        },
        object @ Value::Object(_) => serde_json::from_value(object)
            .map(Task::Action)
            .map_err(|err| err.to_string()),
        other => Err(format!("无法识别的任务：{other}")),
    }
}

impl Task {
    /// 是否是纯函数：结果只取决于占位符的取值，不依赖外部状态。
    ///
    /// 字面量与字符串模板天然是纯的；命令管道由 [`Action::pure`] 声明，
    /// 未展开的简写先按“不纯”处理。
    pub(crate) fn is_pure(&self) -> bool {
        match self {
            Self::Bool(_) | Self::String(_) => true,
            Self::Action(action) => action.pure,
            Self::Builtin(_) => false,
        }
    }

    /// 该任务会写出哪些属性。
    pub(crate) fn property_names(&self, task_name: &str) -> Vec<String> {
        match self {
            Self::Action(action) => action.resolver.properties(task_name),
            _ => vec![task_name.to_owned()],
        }
    }
}

#[cfg(test)]
mod tests;
