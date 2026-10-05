//! 输入锁定：求值配置、解析类型、并发锁定每个输入、写回锁文件。

mod exec;
mod input;

use crate::clap::{Parsed, Update};
use crate::jfsp::deps;
use crate::jfsp::inputs::{self, Config, DEFAULT_GROUP, Declaration};
use crate::jfsp::locked::{
    Builtin, ItemDep, ItemTop, Lock, Tree, resolve_types, version,
};
use crate::jfsp::types::{Type, builtin_types};
use anyhow::{Context, Result, bail};
use log::warn;
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::sync::Arc;
use tokio::task::JoinSet;

use self::exec::{build_env, path_with};
use self::input::{LockedInput, lock_input, required_packages};

/// 读取配置与旧锁文件，锁定全部输入，写回新的锁文件。
pub async fn lock(parsed: &Parsed) -> Result<()> {
    let config_file = inputs::load(&parsed.config).await?;
    let mut old = match Lock::read(&parsed.locked) {
        Ok(lock) => lock,
        Err(err) => {
            warn!("忽略无法读取的锁文件 {}：{err:#}", parsed.locked.display());
            None
        },
    };
    // 版本号用来标记不兼容的格式/语义变化：这时只丢缓存值，保留 config 与类型
    // 数据，否则 autoFollow/defaults/types 会被静默复位
    if let Some(lock) = &mut old {
        if lock.builtin.version != version() {
            warn!(
                "锁文件版本 {} 与当前版本 {} 不一致，将重新锁定",
                lock.builtin.version,
                version()
            );
            lock.locked = Tree::default();
        }
    }

    if let Some(old) = &old {
        for name in old.locked.top.keys() {
            if !config_file.inputs.contains_key(name) {
                warn!("输入 '{name}' 已从配置中移除，其锁定值将被丢弃");
            }
        }
    }

    // 配置：配置文件优先，其次沿用旧锁文件
    let config = config_file
        .config
        .clone()
        .or_else(|| old.as_ref().map(|lock| lock.config.clone()))
        .unwrap_or_default();

    // 类型数据：配置覆盖内置
    let types = resolve_types(&builtin_types(), old.as_ref(), &config);
    let decls = inputs::declarations(config_file.inputs, &types.current)?;

    // 没有输入多半是键名写错了；写回一份空锁会静默丢掉所有锁定值
    if decls.is_empty() {
        bail!("配置文件没有声明任何输入：{}", parsed.config.display());
    }
    report_unknown_list(parsed, &decls);

    // 只按需把用到的类型记进锁文件：配置覆盖过的类型不必记（config 最优先），
    // 没用到的类型更不必全量同步
    let used: HashSet<&str> =
        decls.iter().map(|decl| decl.ftype.as_str()).collect();
    let recorded = |source: &HashMap<String, Type>| {
        source
            .iter()
            .filter(|(name, _)| {
                used.contains(name.as_str())
                    && !config.types.contains_key(*name)
            })
            .map(|(name, btype)| (name.clone(), btype.clone()))
            .collect::<HashMap<String, Type>>()
    };
    let types_data = recorded(&types.builtin);
    let types_bak = recorded(&types.bak);

    // 从 nixpkgs 构建命令任务所需的包环境，并把它的 bin 目录放到 PATH 最前面
    let packages = required_packages(&decls, &types.current);
    let env_path = path_with(build_env(&packages).await?.as_deref());

    let ctx = Arc::new(Ctx {
        types: types.current,
        old_types: types.previous,
        old: old
            .as_ref()
            .map(|lock| lock.locked.top.clone())
            .unwrap_or_default(),
        config,
        update: parsed.update.clone(),
        list: parsed.list.clone(),
        env_path,
    });

    let locked = lock_all(decls, Arc::clone(&ctx)).await?;
    let (top, deps) = split(locked);

    let result = Lock {
        builtin: Builtin {
            version: version(),
            types_data,
            types_bak,
        },
        config: ctx.config.clone(),
        locked: Tree { top, deps },
    };

    result.write(&parsed.locked)
}

/// 锁定过程中的共享上下文。
struct Ctx {
    /// 当前使用的类型数据
    types: HashMap<String, Type>,
    /// 旧锁文件记录的类型数据
    old_types: HashMap<String, Type>,
    /// 旧锁文件记录的输入
    old: HashMap<String, ItemTop>,
    /// 配置
    config: Config,
    /// 更新策略
    update: Update,
    /// 与更新策略配合的名单
    list: HashSet<String>,
    /// 命令任务使用的 `PATH`（已包含包环境的 `bin` 目录）
    env_path: Option<String>,
}

impl Ctx {
    /// 用户是否要求更新这个输入。
    ///
    /// 纯函数不受它影响：只要依赖没变就可以沿用旧值。
    fn requested(&self, decl: &Declaration) -> bool {
        match &self.update {
            Update::Lock => false,
            Update::Update => {
                self.list.is_empty() || self.list.contains(&decl.name)
            },
            Update::UpdateDefault => decl.group == DEFAULT_GROUP,
            Update::UpdateGroup => {
                self.list.is_empty() || self.list.contains(&decl.group)
            },
            Update::UpdateAll => true,
        }
    }

    /// 旧值是否因为任务本身（类型定义或输入类型）变了而失效。
    fn invalidated(&self, decl: &Declaration) -> bool {
        let types_changed =
            self.old_types.get(&decl.ftype) != self.types.get(&decl.ftype);
        let ftype_changed = self
            .old
            .get(&decl.name)
            .is_some_and(|old| old.ftype != decl.ftype);

        types_changed || ftype_changed
    }
}

/// 提示 `--list` 里对不上任何输入/分组的名字。
///
/// 名单写错时 `requested` 会恒为 false，命令静默退化成 `lock`，很容易让人
/// 以为已经刷新过了。
fn report_unknown_list(parsed: &Parsed, decls: &[Declaration]) {
    let known: HashSet<&str> = match parsed.update {
        Update::Update => decls.iter().map(|decl| decl.name.as_str()).collect(),
        Update::UpdateGroup => {
            decls.iter().map(|decl| decl.group.as_str()).collect()
        },
        _ => return,
    };

    for name in &parsed.list {
        if !known.contains(name.as_str()) {
            warn!("--list 里的 '{name}' 不对应任何输入或分组，将被忽略");
        }
    }
}

/// 同时锁定的输入上限：避免一次性拉起过多 nix/git 进程。
const MAX_PARALLEL: usize = 8;

/// 并发锁定全部输入，结果按名字排序。
async fn lock_all(
    decls: Vec<Declaration>,
    ctx: Arc<Ctx>,
) -> Result<BTreeMap<String, LockedInput>> {
    let mut all = BTreeMap::new();

    // 输入之间互不依赖，但一次全放出去可能同时跑太多外部命令，分批并发
    for chunk in decls.chunks(MAX_PARALLEL) {
        let mut tasks = JoinSet::new();
        for decl in chunk {
            let ctx = Arc::clone(&ctx);
            let decl = decl.clone();
            tasks.spawn(async move {
                let name = decl.name.clone();
                lock_input(&ctx, decl).await.map(|input| (name, input))
            });
        }

        while let Some(joined) = tasks.join_next().await {
            let (name, input) = joined.context("输入锁定任务异常中止")??;
            all.insert(name, input);
        }
    }

    Ok(all)
}

/// 把锁定结果拆成 `top` 与 `deps` 两张表。
///
/// 输入按名字排序后依次合并，因此同名依赖的去重结果与并发顺序无关。
fn split(
    locked: BTreeMap<String, LockedInput>,
) -> (HashMap<String, ItemTop>, HashMap<String, ItemDep>) {
    let mut top = HashMap::with_capacity(locked.len());
    let mut deps = HashMap::new();
    let mut conflicts = BTreeSet::new();

    for (name, input) in locked {
        for named in input.deps {
            let dep_name = named.name.clone();
            if deps::insert(&mut deps, named) {
                conflicts.insert(dep_name);
            }
        }
        top.insert(name, input.top);
    }

    if !conflicts.is_empty() {
        warn!(
            "依赖 {} 在不同输入里有不同定义，保留了先出现的",
            conflicts.into_iter().collect::<Vec<String>>().join(", ")
        );
    }

    (top, deps)
}

#[cfg(test)]
mod tests;
