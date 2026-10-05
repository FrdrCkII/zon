//! [`super`] 的单元测试。

use super::*;

#[test]
fn expand_rewrites_builtin_shorthand() {
    match expand(&Task::Builtin("task_hash_unpack".to_owned()))
        .expect("应当可以展开")
    {
        Task::Action(action) => {
            assert_eq!(action.commands, prefetch(true));
            assert!(action.pure);
        },
        other => panic!("期望命令任务，实际为 {other:?}"),
    }
}

#[test]
fn hash_resolver_writes_two_properties_at_once() {
    let mut names = hash_resolver().properties("locked");
    names.sort();
    assert_eq!(names, vec!["hash", "storePath"]);

    let mut produced = hash_resolver()
        .extract(
            "locked",
            r#"{"hash":"sha256-x","storePath":"/nix/store/x"}"#,
        )
        .expect("应当可以解析");
    produced.sort();
    assert_eq!(
        produced,
        vec![
            ("hash".to_owned(), "sha256-x".to_owned()),
            ("storePath".to_owned(), "/nix/store/x".to_owned()),
        ]
    );
}

#[test]
fn hash_tasks_are_pure() {
    // 纯函数才能在强制更新时沿用旧值
    assert!(task_hash().is_pure());
    assert!(task_hash_unpack().is_pure());
    assert!(Task::String("{immut}".to_owned()).is_pure());
    assert!(!Task::Builtin("task_hash".to_owned()).is_pure());
}

#[test]
fn builtin_names_are_recognised() {
    assert!(is_builtin("task_hash"));
    assert!(is_builtin("task_hash_unpack"));
    assert!(!is_builtin("task_missing"));
    assert!(looks_like_builtin("task_missing"));
    assert!(!looks_like_builtin("{url}"));
}

#[test]
fn expand_rejects_unknown_builtin() {
    assert!(expand(&Task::Builtin("missing".to_owned())).is_err());
}

#[test]
fn expand_keeps_plain_tasks() {
    let task = Task::String("{url}".to_owned());
    assert_eq!(expand(&task).expect("应当可以展开"), task);
}
