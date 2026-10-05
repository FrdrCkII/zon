//! 单个输入的锁定，以及依赖的读取。

use super::Ctx;
use crate::jfsp::deps::{self, NamedDep};
use crate::jfsp::inputs::{Declaration, initial_vars};
use crate::jfsp::locked::ItemTop;
use crate::jfsp::types::{
    Task, Type, expand_type, placeholders, resolve_order, substitute,
};
use crate::task::exec::pipeline;
use anyhow::{Context, Result, anyhow, bail};
use log::{info, warn};
use std::collections::{HashMap, HashSet};
use std::path::Path;

/// 依赖读取依赖的属性名：解包后的源码目录。
const STORE_PATH: &str = "storePath";

/// 锁定的结果：输入自身，以及从它源码目录里读出的依赖。
pub(super) struct LockedInput {
    pub top: ItemTop,
    pub deps: Vec<NamedDep>,
}

/// 计算单个输入的全部属性，并读取它的依赖。
pub(super) async fn lock_input(
    ctx: &Ctx,
    decl: Declaration,
) -> Result<LockedInput> {
    let btype = ctx.types.get(&decl.ftype).ok_or_else(|| {
        anyhow!("输入 '{}' 使用了未知的类型 '{}'", decl.name, decl.ftype)
    })?;
    // 内置简写只在运行时展开，锁文件里保留字符串
    let tasks = expand_type(btype)
        .with_context(|| {
            format!(
                "输入 '{}' 的类型 '{}' 含有无法展开的任务",
                decl.name, decl.ftype
            )
        })?
        .tasks;

    // 初始变量：默认值 + 配置参数；参数覆盖的属性直接使用参数值
    let mut vars = initial_vars(&decl.params, &ctx.config);
    // 任务写出的属性全被参数覆盖时，整个任务都不必执行
    let to_compute: HashMap<String, Task> = tasks
        .iter()
        .filter(|(name, task)| {
            !task
                .property_names(name)
                .iter()
                .all(|prop| decl.params.contains_key(prop))
        })
        .map(|(name, task)| (name.clone(), task.clone()))
        .collect();

    let requested = ctx.requested(&decl);
    let old = ctx.old.get(&decl.name);
    // 旧值不可信的情形：类型定义变了，或解包出来的源码目录被回收了
    let invalidated = ctx.invalidated(&decl) || source_missing(old);
    let mut computed: HashSet<String> = HashSet::new();

    for layer in resolve_order(&to_compute)? {
        for prop in layer {
            let task = to_compute
                .get(&prop)
                .ok_or_else(|| anyhow!("属性 '{prop}' 不存在"))?;

            let produced = match substitute(task, &vars) {
                Task::Bool(flag) => vec![(prop.clone(), flag.to_string())],
                Task::String(value) => vec![(prop.clone(), value)],
                Task::Builtin(name) => bail!(
                    "输入 '{}' 的属性 '{prop}' 使用了未展开的内置任务 '{name}'",
                    decl.name
                ),
                Task::Action(action) => {
                    // 一个任务可能写出多个属性：必须全都还在缓存里才算命中，
                    // 缺了任何一个都要重新执行，否则那个属性再也补不回来
                    let expected = action.resolver.properties(&prop);
                    let cached = fully_cached(old, &expected);
                    let changed = deps_changed(task, &vars, old);
                    let run = should_run(
                        cached,
                        invalidated,
                        changed,
                        requested,
                        task.is_pure(),
                    );

                    if run {
                        info!("输入 '{}'：执行属性 '{prop}'", decl.name);
                        let output =
                            pipeline(&action.commands, ctx.env_path.as_deref())
                                .await
                                .with_context(|| {
                                    format!(
                                        "输入 '{}' 的属性 '{prop}' 执行失败",
                                        decl.name
                                    )
                                })?;
                        let produced = action
                            .resolver
                            .extract(&prop, &output)
                            .with_context(|| {
                                format!(
                                    "输入 '{}' 的属性 '{prop}' 无法解析命令输出",
                                    decl.name
                                )
                            })?;
                        for name in &expected {
                            if !produced.iter().any(|(key, _)| key == name) {
                                warn!(
                                    "输入 '{}'：属性 '{prop}' 的输出缺少 '{name}'，下次仍会重新执行",
                                    decl.name
                                );
                            }
                        }
                        produced
                    } else {
                        expected
                            .iter()
                            .filter_map(|name| {
                                old.and_then(|old| old.locked.get(name))
                                    .map(|value| (name.clone(), value.clone()))
                            })
                            .collect()
                    }
                },
            };

            for (name, value) in produced {
                computed.insert(name.clone());
                // 显式声明的参数优先，避免任务输出意外覆盖
                if decl.params.contains_key(&name) {
                    continue;
                }
                if vars.contains_key(&name) {
                    warn!(
                        "输入 '{}'：任务 '{prop}' 写出的属性 '{name}' 覆盖了已有的值",
                        decl.name
                    );
                }
                vars.insert(name, value);
            }
        }
    }

    // 锁定值：声明的参数、计算出的属性，以及被任务引用到的默认值
    let referenced: HashSet<String> =
        tasks.values().flat_map(placeholders).collect();
    let locked: HashMap<String, String> = vars
        .into_iter()
        .filter(|(name, _)| {
            decl.params.contains_key(name)
                || computed.contains(name)
                || referenced.contains(name)
        })
        .collect();

    let deps = read_deps(&locked, &decl, ctx.config.auto_follow)?;

    Ok(LockedInput {
        top: ItemTop {
            ftype: decl.ftype,
            group: decl.group,
            locked,
        },
        deps,
    })
}

/// 从输入的源码目录里读取依赖。
///
/// 源码目录来自 `storePath` 属性：没有它（或目录已被回收）就没有依赖。
fn read_deps(
    locked: &HashMap<String, String>,
    decl: &Declaration,
    auto_follow: bool,
) -> Result<Vec<NamedDep>> {
    let Some(store_path) = locked.get(STORE_PATH) else {
        return Ok(Vec::new());
    };

    let dir = Path::new(store_path);
    if !dir.is_dir() {
        warn!("输入 '{}' 的源码目录不存在：{store_path}", decl.name);
        return Ok(Vec::new());
    }

    deps::read(dir, &decl.name, !auto_follow)
        .with_context(|| format!("输入 '{}' 的依赖读取失败", decl.name))
}

/// 解包后的源码目录是否已经不在 store 里（被回收）。
///
/// 这时旧值不可信：重跑一次才能把目录恢复出来，否则依赖会被静默丢掉。
fn source_missing(old: Option<&ItemTop>) -> bool {
    old.and_then(|old| old.locked.get(STORE_PATH))
        .is_some_and(|path| !Path::new(path).is_dir())
}

/// 命令任务的依赖值是否发生变化（缺少旧值时视为变化）。
///
/// 两边都取不到的名字（`{print $1}` 这类字面花括号）不算依赖，否则每次都会
/// 判定为“变了”，命令永远重跑。
fn deps_changed(
    task: &Task,
    vars: &HashMap<String, String>,
    old: Option<&ItemTop>,
) -> bool {
    let Some(old) = old else {
        return true;
    };

    placeholders(task).into_iter().any(|dep| {
        match (vars.get(&dep), old.locked.get(&dep)) {
            (Some(new), Some(previous)) => new != previous,
            (None, None) => false,
            _ => true,
        }
    })
}

/// 是否需要重新执行命令任务。
///
/// 纯函数的结果只取决于占位符的取值，因此依赖没变、任务定义也没变时，
/// 即使要求强制更新也直接沿用旧值；不纯的任务在强制更新时必须重跑。
fn should_run(
    cached: bool,
    invalidated: bool,
    changed: bool,
    requested: bool,
    pure: bool,
) -> bool {
    !cached || invalidated || changed || (requested && !pure)
}

/// 任务写出的属性是否全都还在缓存里。
///
/// 多属性任务缺任何一个都不算命中：否则缺失的属性会一直留在旧锁文件里，
/// 再也不会被补回来。
fn fully_cached(old: Option<&ItemTop>, expected: &[String]) -> bool {
    old.is_some_and(|old| {
        expected.iter().all(|name| old.locked.contains_key(name))
    })
}

/// 收集所有声明的输入用到的包。
pub(super) fn required_packages(
    decls: &[Declaration],
    types: &HashMap<String, Type>,
) -> HashSet<String> {
    decls
        .iter()
        .filter_map(|decl| types.get(&decl.ftype))
        .flat_map(|btype| btype.packages.iter().cloned())
        .collect()
}

#[cfg(test)]
mod tests;
