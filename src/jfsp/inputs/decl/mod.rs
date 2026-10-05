//! 输入声明：校验配置里的输入，并构造初始变量表。

use super::Config;
use crate::jfsp::types::{Type, expand_type};
use anyhow::{Context, Result, bail};
use log::warn;
use serde_json::Value;
use std::collections::{HashMap, HashSet};

/// 未显式声明 `group` 的输入所属的分组。
pub const DEFAULT_GROUP: &str = "default";

/// 单个输入的声明。
#[derive(Clone, Debug)]
pub struct Declaration {
    /// 输入名称
    pub name: String,
    /// 类型名称
    pub ftype: String,
    /// 更新分组，缺省为 [`DEFAULT_GROUP`]
    pub group: String,
    /// 配置声明的参数
    pub params: HashMap<String, String>,
}

/// 校验并规范化输入声明。返回按名称排序的声明列表。
pub fn declarations(
    inputs: HashMap<String, HashMap<String, Value>>,
    types: &HashMap<String, Type>,
) -> Result<Vec<Declaration>> {
    // 先排序再校验：出错时报的是哪个输入，与 HashMap 的随机顺序无关
    let mut inputs: Vec<(String, HashMap<String, Value>)> =
        inputs.into_iter().collect();
    inputs.sort_by(|a, b| a.0.cmp(&b.0));

    let mut decls = Vec::with_capacity(inputs.len());

    for (name, attrs) in inputs {
        let mut ftype = None;
        let mut params = HashMap::with_capacity(attrs.len());

        for (key, value) in attrs {
            if key == "ftype" {
                ftype = Some(match value {
                    Value::String(ftype) => ftype,
                    other => {
                        bail!(
                            "输入 '{name}' 的 ftype 必须是字符串，实际为 {other}"
                        )
                    },
                });
            } else {
                params
                    .insert(key.clone(), value_to_string(&name, &key, &value)?);
            }
        }

        let ftype =
            ftype.with_context(|| format!("输入 '{name}' 缺少 ftype 字段"))?;
        let btype = types.get(&ftype).with_context(|| {
            let mut known: Vec<&str> =
                types.keys().map(String::as_str).collect();
            known.sort_unstable();
            format!(
                "输入 '{name}' 使用了未知的类型 '{ftype}'；可用类型：{}",
                known.join(", ")
            )
        })?;

        // 参数覆盖了类型会算出的属性：不是错误，但值得提醒（对应任务不会执行）
        let expanded = expand_type(btype)
            .with_context(|| format!("类型 '{ftype}' 含有无法展开的任务"))?;
        let produced: HashSet<String> = expanded
            .tasks
            .iter()
            .flat_map(|(task, value)| value.property_names(task))
            .collect();
        for key in params.keys() {
            if produced.contains(key) {
                warn!(
                    "输入 '{name}' 的参数 '{key}' 覆盖了类型 '{ftype}' 会算出的属性"
                );
            }
        }

        // 空字符串不是有意义的分组，归一化掉，否则它既不属于默认分组也
        // 无法被 --list 命中（空串在拆分时就被丢掉了）
        let group = match params.get("group") {
            Some(group) if !group.is_empty() => group.clone(),
            _ => DEFAULT_GROUP.to_owned(),
        };

        decls.push(Declaration {
            name,
            ftype,
            group,
            params,
        });
    }

    Ok(decls)
}

/// 构造初始变量表：先放入 `Config::defaults` 提供的默认值，再放入配置声明的
/// 参数（参数优先）。
///
/// 锁定过程中取不到值的占位符会回退到这张表里查找，例如 `{hashType}` 默认
/// 取 `defaults` 中的 `hashType`；某个输入显式声明了同名参数时以参数为准。
pub fn initial_vars(
    params: &HashMap<String, String>,
    config: &Config,
) -> HashMap<String, String> {
    let mut vars = config.defaults.clone();
    vars.extend(params.iter().map(|(k, v)| (k.clone(), v.clone())));
    vars
}

/// 把配置中的参数值转换为字符串。
fn value_to_string(name: &str, key: &str, value: &Value) -> Result<String> {
    super::config::scalar_to_string(value)
        .with_context(|| format!("输入 '{name}' 的参数 '{key}' 不合法"))
}

#[cfg(test)]
mod tests;
