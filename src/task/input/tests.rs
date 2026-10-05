use super::*;
use crate::jfsp::types::builtin_types;

fn decl(name: &str, ftype: &str) -> Declaration {
    Declaration {
        name: name.to_owned(),
        ftype: ftype.to_owned(),
        group: crate::jfsp::inputs::DEFAULT_GROUP.to_owned(),
        params: HashMap::new(),
    }
}

#[test]
fn required_packages_unions_selected_types() {
    let types = builtin_types();
    let decls = vec![decl("a", "common"), decl("b", "gitArchive")];

    let packages = required_packages(&decls, &types);
    assert!(packages.contains("git"));
    assert!(packages.contains("coreutils"));
    // common 不需要额外的包
    assert!(!packages.contains("curl"));
}

#[test]
fn required_packages_is_empty_without_inputs() {
    assert!(required_packages(&[], &builtin_types()).is_empty());
}

#[test]
fn should_run_reuses_cached_values_when_nothing_changed() {
    // 有缓存、类型没变、依赖没变
    assert!(!should_run(true, false, false, false, false));
    assert!(!should_run(true, false, false, false, true));
}

#[test]
fn should_run_is_lazy_for_pure_tasks_under_forced_update() {
    // 纯函数：即使要求更新，依赖没变也沿用旧值
    assert!(!should_run(true, false, false, true, true));
    // 不纯的任务（如 git ls-remote）必须重跑
    assert!(should_run(true, false, false, true, false));
}

#[test]
fn should_run_reruns_without_cache_or_after_invalidation() {
    assert!(should_run(false, false, false, false, true));
    assert!(should_run(true, false, true, false, true));
    assert!(should_run(true, true, false, false, true));
}

/// 构造带指定属性的缓存条目。
fn item(pairs: &[(&str, &str)]) -> ItemTop {
    ItemTop {
        ftype: "demo".to_owned(),
        group: crate::jfsp::inputs::DEFAULT_GROUP.to_owned(),
        locked: pairs
            .iter()
            .map(|(k, v)| ((*k).to_owned(), (*v).to_owned()))
            .collect(),
    }
}

#[test]
fn multi_property_tasks_are_reused_only_when_every_property_is_cached() {
    let expected = ["locked".to_owned(), "storePath".to_owned()];

    // 全都在缓存里才算命中
    assert!(fully_cached(
        Some(&item(&[
            ("locked", "sha256-x"),
            ("storePath", "/nix/store/x")
        ])),
        &expected
    ));

    // 缺任何一个都要重新执行，否则缺失的属性再也补不回来
    assert!(!fully_cached(
        Some(&item(&[("locked", "sha256-x")])),
        &expected
    ));
    assert!(!fully_cached(
        Some(&item(&[("storePath", "/nix/store/x")])),
        &expected
    ));
    assert!(!fully_cached(Some(&item(&[])), &expected));
    assert!(!fully_cached(None, &expected));

    // 单属性任务与原来的行为一致
    let single = ["rev".to_owned()];
    assert!(fully_cached(Some(&item(&[("rev", "abc")])), &single));
    assert!(!fully_cached(Some(&item(&[])), &single));
}

#[test]
fn read_deps_skips_inputs_without_store_path() {
    let decl = decl("hjem", "gitArchive");
    assert!(
        read_deps(&HashMap::new(), &decl, true)
            .expect("应当可以读取")
            .is_empty()
    );

    let mut locked = HashMap::new();
    locked.insert("storePath".to_owned(), "/nix/store/not-there".to_owned());
    assert!(
        read_deps(&locked, &decl, true)
            .expect("应当可以读取")
            .is_empty()
    );
}

#[test]
fn source_missing_detects_a_collected_store_path() {
    assert!(!source_missing(None));
    assert!(!source_missing(Some(&item(&[]))));
    // 存在的目录不算丢失
    assert!(!source_missing(Some(&item(&[("storePath", "/")]))));
    // 被 GC 掉的目录要触发重算
    assert!(source_missing(Some(&item(&[(
        "storePath",
        "/nix/store/not-there"
    )]))));
}

#[test]
fn deps_changed_ignores_literal_braces() {
    use crate::jfsp::types::{Action, Resolver};

    let raw = |argv: &[&str]| {
        Task::Action(Action {
            resolver: Resolver::Raw,
            pure: false,
            commands: vec![argv.iter().map(|arg| (*arg).to_owned()).collect()],
        })
    };
    let old = item(&[("v", "x")]);

    // awk 的程序体在两边都取不到值：不算依赖，否则每次都会重跑
    let awk = raw(&["awk", "{print $1}"]);
    assert!(!deps_changed(&awk, &HashMap::new(), Some(&old)));

    // 真依赖变化仍然要被发现
    let uses_v = raw(&["printf", "{v}"]);
    assert!(deps_changed(
        &uses_v,
        &HashMap::from([("v".to_owned(), "y".to_owned())]),
        Some(&old)
    ));
    assert!(!deps_changed(
        &uses_v,
        &HashMap::from([("v".to_owned(), "x".to_owned())]),
        Some(&old)
    ));
}
