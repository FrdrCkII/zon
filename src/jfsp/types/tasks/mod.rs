//! 预置任务：以函数形式提供的、可复用的任务定义，以及内置简写的展开。

use super::{Action, Resolver, Task, Type};
use anyhow::{Result, bail};
use std::collections::HashMap;

macro_rules! s {
    ($($value:expr)?) => {{
        $($value.to_owned())*
    }};
}

macro_rules! svec {
    ($($str:expr),* $(,)?) => {
        vec![$(s!($str)),*]
    };
}

/// 内置任务名的前缀，用来识别拼错的简写。
const PREFIX: &str = "task_";

/// 内置简写的最大展开层数，用来兜住意外的循环引用。
const MAX_DEPTH: usize = 16;

/// 是否是已注册的内置任务名。
pub(super) fn is_builtin(name: &str) -> bool {
    builtin_task(name).is_some()
}

/// 名字看起来是否像内置任务（用于把拼错的简写报出来，而不是当成字面量）。
pub(super) fn looks_like_builtin(name: &str) -> bool {
    name.starts_with(PREFIX)
}

/// 展开任务中的内置简写（[`Task::Builtin`]）。
pub fn expand(task: &Task) -> Result<Task> {
    let mut current = task.clone();
    for _ in 0..MAX_DEPTH {
        let name = match &current {
            Task::Builtin(name) => name.clone(),
            _ => return Ok(current),
        };
        let Some(next) = builtin_task(&name) else {
            bail!("未知的内置任务：{name}");
        };
        current = next;
    }

    bail!("内置任务的展开层数过深，可能存在循环引用")
}

/// 展开类型中的全部任务。
pub fn expand_type(btype: &Type) -> Result<Type> {
    let tasks = btype
        .tasks
        .iter()
        .map(|(name, task)| Ok((name.clone(), expand(task)?)))
        .collect::<Result<HashMap<String, Task>>>()?;

    Ok(Type {
        packages: btype.packages.clone(),
        tasks,
    })
}

/// 按名字调用内置任务函数。
fn builtin_task(name: &str) -> Option<Task> {
    Some(match name {
        "task_hash" => task_hash(),
        "task_hash_unpack" => task_hash_unpack(),
        _ => return None,
    })
}

/// `nix store prefetch-file` 的命令管道。
///
/// `unpack` 为真时会解包，此时输出的 `storePath` 是解包后的源码目录，
/// 依赖读取正需要它。
fn prefetch(unpack: bool) -> Vec<Vec<String>> {
    let mut argv = svec![
        "nix",
        "store",
        "prefetch-file",
        "--extra-experimental-features",
        "nix-command",
        "--name",
        "source",
        "--hash-type",
        "{hashType}",
        "--json",
        "--no-pretty",
        "--log-format",
        "bar",
    ];
    if unpack {
        argv.push(s!("--unpack"));
    }
    argv.push(s!("{immut}"));
    vec![argv]
}

/// 一次取出 `{immut}` 的哈希与源码目录。
///
/// 这是 [`Resolver::Json`] 的典型用法：一个任务写出两个属性，昂贵的
/// `nix store prefetch-file` 只跑一次。属性名可以自定义，这里用 `hash`
/// 承载哈希、`storePath` 承载源码目录。
fn hash_resolver() -> Resolver {
    Resolver::Json(HashMap::from([
        ("hash".to_owned(), "hash".to_owned()),
        ("storePath".to_owned(), "storePath".to_owned()),
    ]))
}

/// 计算 `{immut}` 的哈希。
///
/// `immut` 是不可变链接，同名输入必然得到同名输出，因此是纯函数。
fn task_hash() -> Task {
    Task::Action(Action {
        resolver: hash_resolver(),
        pure: true,
        commands: prefetch(false),
    })
}

/// 同 [`task_hash`]，但会解包 `{immut}`（适合压缩包）。
fn task_hash_unpack() -> Task {
    Task::Action(Action {
        resolver: hash_resolver(),
        pure: true,
        commands: prefetch(true),
    })
}

#[cfg(test)]
mod tests;
