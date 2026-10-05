//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::types::Resolver;

fn string_task(template: &str) -> Task {
    Task::String(template.to_owned())
}

fn command_task(stages: &[&[&str]]) -> Task {
    Task::Action(Action {
        resolver: Resolver::Raw,
        pure: false,
        commands: stages
            .iter()
            .map(|argv| argv.iter().map(|arg| (*arg).to_owned()).collect())
            .collect(),
    })
}

fn vars(pairs: &[(&str, &str)]) -> HashMap<String, String> {
    pairs
        .iter()
        .map(|(k, v)| ((*k).to_owned(), (*v).to_owned()))
        .collect()
}

#[test]
fn substitute_keeps_unknown_placeholders() {
    let task = string_task("{repo}/archive/{rev}.tar.gz");
    let vars = vars(&[("repo", "https://example.com/a")]);
    assert_eq!(
        substitute(&task, &vars),
        string_task("https://example.com/a/archive/{rev}.tar.gz")
    );
}

#[test]
fn placeholders_lists_every_braced_name_in_order() {
    let task = command_task(&[&["git", "ls-remote", "{repo}", "{ref}"]]);
    assert_eq!(placeholders(&task), vec!["repo", "ref"]);
}

#[test]
fn literal_braces_are_left_alone() {
    // awk 的程序体与 JSON 字面量都不是变量表里的键，原样保留即可
    let task = command_task(&[&["awk", "{print $1}"]]);
    assert_eq!(substitute(&task, &vars(&[])), task);

    let json = command_task(&[&["printf", r#"{"hash":"sha256-x"}"#]]);
    assert_eq!(substitute(&json, &vars(&[])), json);
}

#[test]
fn placeholders_can_be_a_literal_brace_only_if_defined() {
    // 键名不要求是标识符：只要变量表里有，就替换
    let task = string_task("{print $1}");
    assert_eq!(
        substitute(&task, &vars(&[("print $1", "x")])),
        string_task("x")
    );
}

#[test]
fn braces_are_matched_greedily() {
    let task = string_task("{a}{b}");
    assert_eq!(
        substitute(&task, &vars(&[("a", "1"), ("b", "2")])),
        string_task("12")
    );
}
