//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::deps::NamedDep;
use crate::jfsp::locked::ItemDep;
use crate::jfsp::types::Task;

fn ctx(update: Update, list: &[&str]) -> Ctx {
    Ctx {
        types: HashMap::new(),
        old_types: HashMap::new(),
        old: HashMap::new(),
        config: Config::default(),
        update,
        list: list.iter().map(|name| (*name).to_owned()).collect(),
        env_path: None,
    }
}

fn decl(name: &str, group: &str) -> Declaration {
    Declaration {
        name: name.to_owned(),
        ftype: "common".to_owned(),
        group: group.to_owned(),
        params: HashMap::new(),
    }
}

#[test]
fn requested_follows_update_mode() {
    let lock = ctx(Update::Lock, &[]);
    assert!(!lock.requested(&decl("hjem", DEFAULT_GROUP)));

    let update = ctx(Update::Update, &["hjem"]);
    assert!(update.requested(&decl("hjem", DEFAULT_GROUP)));
    assert!(!update.requested(&decl("agenix", DEFAULT_GROUP)));

    let all = ctx(Update::Update, &[]);
    assert!(all.requested(&decl("agenix", DEFAULT_GROUP)));

    let default = ctx(Update::UpdateDefault, &[]);
    assert!(default.requested(&decl("hjem", DEFAULT_GROUP)));
    assert!(!default.requested(&decl("hjem", "other")));

    let group = ctx(Update::UpdateGroup, &["other"]);
    assert!(group.requested(&decl("hjem", "other")));
    assert!(!group.requested(&decl("hjem", DEFAULT_GROUP)));

    assert!(ctx(Update::UpdateAll, &[]).requested(&decl("hjem", "other")));
}

#[test]
fn invalidated_tracks_task_definitions_and_types() {
    let unchanged = ctx(Update::Lock, &[]);
    assert!(!unchanged.invalidated(&decl("hjem", DEFAULT_GROUP)));

    // 类型定义变化时旧值失效
    let empty = Type {
        packages: HashSet::new(),
        tasks: HashMap::new(),
    };
    let mut changed = ctx(Update::Lock, &[]);
    changed.old_types.insert("common".to_owned(), empty.clone());
    changed.types.insert("common".to_owned(), empty);
    assert!(!changed.invalidated(&decl("hjem", DEFAULT_GROUP)));

    changed
        .types
        .get_mut("common")
        .expect("应当有类型")
        .tasks
        .insert("v".to_owned(), Task::String("new".to_owned()));
    assert!(changed.invalidated(&decl("hjem", DEFAULT_GROUP)));

    // 输入换了类型时旧值失效
    let mut retyped = ctx(Update::Lock, &[]);
    retyped.old.insert(
        "hjem".to_owned(),
        ItemTop {
            ftype: "gitArchive".to_owned(),
            group: DEFAULT_GROUP.to_owned(),
            locked: HashMap::new(),
        },
    );
    assert!(retyped.invalidated(&decl("hjem", DEFAULT_GROUP)));
}

#[test]
fn split_dedupes_dependencies_by_name() {
    let dep = |ftype: &str| ItemDep {
        ftype: ftype.to_owned(),
        locked: serde_json::json!({ "rev": "aaa" }),
    };
    let item = |name: &str| ItemTop {
        ftype: name.to_owned(),
        group: DEFAULT_GROUP.to_owned(),
        locked: HashMap::new(),
    };
    let named = |name: &str, ftype: &str| NamedDep {
        name: name.to_owned(),
        dep: dep(ftype),
    };

    let mut locked = BTreeMap::new();
    locked.insert(
        "a".to_owned(),
        LockedInput {
            top: item("a"),
            deps: vec![named("nixpkgs", "github")],
        },
    );
    locked.insert(
        "b".to_owned(),
        LockedInput {
            top: item("b"),
            deps: vec![named("nixpkgs", "git")],
        },
    );

    let (top, deps) = split(locked);
    assert_eq!(top.len(), 2);
    // 先合并输入 a，因此保留它的定义
    assert_eq!(deps["nixpkgs"].ftype, "github");
}
