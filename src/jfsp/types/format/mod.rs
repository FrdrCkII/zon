//! 占位符替换。
//!
//! 只支持 `{key}`：在变量表里查值（变量表已包含 `config.defaults`）。查不到
//! 就原样保留，于是 `awk '{print $1}'` 这类字面花括号天然不会被替换，不需要
//! 再去区分“像不像标识符”；真缺了必要字段，命令自己会出错。

use super::{Action, Task};
use std::collections::{HashMap, HashSet};

/// 提取任务中的全部占位符名称（去重，保持出现顺序）。
pub(crate) fn placeholders(task: &Task) -> Vec<String> {
    let mut names = Vec::new();
    let mut seen = HashSet::new();
    each_placeholder(task, |name| {
        if seen.insert(name.to_owned()) {
            names.push(name.to_owned());
        }
    });
    names
}

/// 用变量表替换任务中的占位符（单次替换，不递归）；取不到值就原样保留。
pub(crate) fn substitute(task: &Task, vars: &HashMap<String, String>) -> Task {
    let replace =
        |text: &str| map_placeholders(text, |name| vars.get(name).cloned());

    match task {
        Task::Bool(flag) => Task::Bool(*flag),
        Task::Builtin(name) => Task::Builtin(name.clone()),
        Task::String(template) => Task::String(replace(template)),
        Task::Action(action) => Task::Action(Action {
            resolver: action.resolver.clone(),
            pure: action.pure,
            commands: action
                .commands
                .iter()
                .map(|argv| argv.iter().map(|arg| replace(arg)).collect())
                .collect(),
        }),
    }
}

/// 遍历任务中的全部占位符。
fn each_placeholder<F>(task: &Task, mut f: F)
where
    F: FnMut(&str),
{
    let mut visit = |name: &str| {
        f(name);
        None
    };

    match task {
        Task::Bool(_) | Task::Builtin(_) => {},
        Task::String(template) => {
            map_placeholders(template, &mut visit);
        },
        Task::Action(action) => {
            for argv in &action.commands {
                for arg in argv {
                    map_placeholders(arg, &mut visit);
                }
            }
        },
    }
}

/// 遍历字符串中的花括号并替换；`f` 返回 `None` 时原样保留。
fn map_placeholders<F>(text: &str, mut f: F) -> String
where
    F: FnMut(&str) -> Option<String>,
{
    let mut out = String::with_capacity(text.len());
    let mut rest = text;

    while let Some(start) = rest.find('{') {
        out.push_str(&rest[..start]);
        let after = &rest[start + 1..];

        // 未闭合的花括号原样保留
        let Some(end) = after.find('}') else {
            out.push('{');
            rest = after;
            continue;
        };

        let inner = &after[..end];
        match f(inner.trim()) {
            Some(value) => out.push_str(&value),
            None => {
                out.push('{');
                out.push_str(inner);
                out.push('}');
            },
        }
        rest = &after[end + 1..];
    }

    out.push_str(rest);
    out
}

#[cfg(test)]
mod tests;
