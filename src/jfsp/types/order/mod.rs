//! 任务依赖排序。

use super::{Task, placeholders};
use anyhow::{Result, bail};
use std::collections::{HashMap, HashSet};

/// Kahn 拓扑排序：按依赖分层返回需要计算的任务名；存在循环依赖时报错。
///
/// 依赖看的是**属性**：占位符引用到哪个属性，就依赖写出那个属性的任务。
/// 任务对自身的引用不算依赖。
pub(crate) fn resolve_order(
    tasks: &HashMap<String, Task>,
) -> Result<Vec<Vec<String>>> {
    // 属性名 -> 写出它的任务（一个任务可以写出多个属性）。
    // 按任务名排序后再收集：同一个属性被多个任务写出时，选中的是确定的那个
    // （运行时还会就覆盖给出告警）。
    let mut names: Vec<&String> = tasks.keys().collect();
    names.sort_unstable();
    let mut producers: HashMap<String, String> = HashMap::new();
    for name in names {
        for prop in tasks[name].property_names(name) {
            producers.entry(prop).or_insert_with(|| name.clone());
        }
    }

    let mut successors: HashMap<String, Vec<String>> = HashMap::new();
    let mut indegree: HashMap<String, usize> =
        tasks.keys().map(|name| (name.clone(), 0)).collect();

    for (name, task) in tasks {
        let deps: HashSet<String> = placeholders(task)
            .into_iter()
            .filter_map(|dep| producers.get(&dep).cloned())
            .filter(|dep| dep != name)
            .collect();

        if let Some(degree) = indegree.get_mut(name) {
            *degree += deps.len();
        }
        for dep in deps {
            successors.entry(dep).or_default().push(name.clone());
        }
    }

    let mut queue: Vec<String> = indegree
        .iter()
        .filter(|(_, degree)| **degree == 0)
        .map(|(name, _)| name.clone())
        .collect();
    queue.sort_unstable();

    let mut layers = Vec::new();
    let mut processed = 0;
    while !queue.is_empty() {
        let layer = std::mem::take(&mut queue);

        for name in &layer {
            processed += 1;
            for successor in successors.get(name).into_iter().flatten() {
                if let Some(degree) = indegree.get_mut(successor) {
                    *degree -= 1;
                    if *degree == 0 {
                        queue.push(successor.clone());
                    }
                }
            }
        }

        queue.sort_unstable();
        layers.push(layer);
    }

    if processed != tasks.len() {
        bail!("类型数据中存在循环依赖，无法确定属性的计算顺序");
    }
    Ok(layers)
}

#[cfg(test)]
mod tests;
