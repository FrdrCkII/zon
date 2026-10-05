//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::locked::{Builtin, Tree, version};
use crate::jfsp::types::{Task, builtin_types};
use std::collections::HashSet;

/// 构造只含一个字符串任务的类型，便于比较类型定义。
fn btype(value: &str) -> Type {
    Type {
        packages: HashSet::new(),
        tasks: HashMap::from([(
            "v".to_owned(),
            Task::String(value.to_owned()),
        )]),
    }
}

fn types(pairs: &[(&str, &str)]) -> HashMap<String, Type> {
    pairs
        .iter()
        .map(|(name, value)| ((*name).to_owned(), btype(value)))
        .collect()
}

fn task_value(btype: &Type, name: &str) -> String {
    match &btype.tasks[name] {
        Task::String(text) => text.clone(),
        other => panic!("期望字符串任务，实际为 {other:?}"),
    }
}

#[test]
fn config_types_override_builtins() {
    let types = resolve_types(
        &types(&[("t", "builtin")]),
        None,
        &Config {
            types: types(&[("t", "config")]),
            ..Config::default()
        },
    );
    assert_eq!(task_value(&types.current["t"], "v"), "config");
}

#[test]
fn previous_records_what_the_old_lock_used() {
    // 上次是用 config.types 覆盖的，所以 typesData 里不记录这个类型
    let old = Lock {
        builtin: Builtin {
            version: version(),
            types_data: HashMap::new(),
            types_bak: HashMap::new(),
        },
        config: Config {
            types: types(&[("t", "old-config")]),
            ..Config::default()
        },
        locked: Tree::default(),
    };

    let types =
        resolve_types(&types(&[("t", "new")]), Some(&old), &Config::default());
    assert_eq!(task_value(&types.current["t"], "v"), "new");
    assert_eq!(task_value(&types.previous["t"], "v"), "old-config");
    assert_eq!(types.builtin.len(), 1);
}

#[test]
fn builtin_types_are_stable_for_resolution() {
    // 内置类型与自己比较时不应产生“类型变化”
    let builtin = builtin_types();
    let old = Lock {
        builtin: Builtin {
            version: version(),
            types_data: builtin.clone(),
            types_bak: HashMap::new(),
        },
        config: Config::default(),
        locked: Tree::default(),
    };

    let types = resolve_types(&builtin, Some(&old), &Config::default());
    assert!(types.bak.is_empty());
    assert_eq!(types.previous, types.current);
}

#[test]
fn changed_builtin_is_preserved_and_used() {
    // 程序改过内置类型：旧定义保留到 bak，并按旧定义解析
    let builtin = types(&[("t", "new")]);
    let old = Lock {
        builtin: Builtin {
            version: version(),
            types_data: types(&[("t", "old")]),
            types_bak: HashMap::new(),
        },
        config: Config::default(),
        locked: Tree::default(),
    };

    let types = resolve_types(&builtin, Some(&old), &Config::default());
    assert_eq!(task_value(&types.bak["t"], "v"), "old");
    assert_eq!(task_value(&types.current["t"], "v"), "old");
    // 旧锁当初生效的就是旧定义，所以不算“类型变化”
    assert_eq!(types.previous, types.current);
}

#[test]
fn config_override_drops_the_preserved_definition() {
    let builtin = types(&[("t", "new")]);
    let old = Lock {
        builtin: Builtin {
            version: version(),
            types_data: types(&[("t", "old")]),
            types_bak: HashMap::new(),
        },
        config: Config::default(),
        locked: Tree::default(),
    };

    let config = Config {
        types: types(&[("t", "mine")]),
        ..Config::default()
    };
    let types = resolve_types(&builtin, Some(&old), &config);
    assert!(types.bak.is_empty());
    assert_eq!(task_value(&types.current["t"], "v"), "mine");
    assert_eq!(task_value(&types.previous["t"], "v"), "old");
}

#[test]
fn preserved_definition_is_stable_across_runs() {
    let builtin = types(&[("t", "new")]);
    // 第一次升级：typesData 还是旧的，于是旧定义进了 typesBak
    let first = legacy_types(
        &builtin,
        &types(&[("t", "old")]),
        &HashMap::new(),
        &HashMap::new(),
    );
    assert_eq!(task_value(&first["t"], "v"), "old");

    // 第二次运行：typesData 已经是新定义，旧定义靠 typesBak 继续留着
    let second = legacy_types(&builtin, &builtin, &first, &HashMap::new());
    assert_eq!(task_value(&second["t"], "v"), "old");
}
