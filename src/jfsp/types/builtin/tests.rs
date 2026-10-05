//! [`super`] 的单元测试。

use super::*;

fn hash_properties(btype: &Type) -> Vec<String> {
    let task = btype.tasks.get("locked").expect("应当有 locked 任务");
    // 简写保持原样，等运行任务时再展开
    assert_eq!(task, &Task::Builtin("task_hash_unpack".to_owned()));

    match crate::jfsp::types::expand(task).expect("应当可以展开") {
        Task::Action(action) => {
            let mut names = action.resolver.properties("locked");
            names.sort();
            names
        },
        other => panic!("期望命令任务，实际为 {other:?}"),
    }
}

#[test]
fn builtin_types_carry_packages_and_tasks() {
    let types = builtin_types();
    assert_eq!(types.len(), 5);

    for (name, btype) in &types {
        assert!(!btype.tasks.is_empty(), "类型 {name} 应当声明任务");
        assert!(
            matches!(btype.tasks["locked"], Task::Builtin(_)),
            "类型 {name} 的简写不应被展开"
        );
    }

    let git = &types["gitArchive"];
    assert!(git.packages.contains("git"));
    assert!(git.tasks.contains_key("rev"));
}

#[test]
fn locked_task_writes_hash_and_store_path() {
    for (name, btype) in &builtin_types() {
        assert_eq!(
            hash_properties(btype),
            vec!["hash", "storePath"],
            "类型 {name} 的 locked 任务应当一次写出两个属性"
        );
    }
}
