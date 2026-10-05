//! [`super`] 的单元测试。

use super::*;

fn flake_lock() -> &'static str {
    r#"{
      "nodes": {
        "root": { "inputs": { "nixpkgs": "nixpkgs", "flake-utils": "flake-utils" } },
        "nixpkgs": {
          "locked": { "type": "github", "owner": "NixOS", "repo": "nixpkgs", "rev": "aaa" }
        },
        "flake-utils": {
          "locked": { "type": "github", "owner": "numtide", "repo": "flake-utils", "rev": "bbb" },
          "inputs": { "systems": "systems" }
        },
        "systems": {
          "locked": { "type": "github", "owner": "nix-systems", "repo": "default", "rev": "ccc" }
        }
      },
      "root": "root",
      "version": 7
    }"#
}

/// 真实 flake.lock 用属性路径数组表示 follows，并且会有 `flake = false` 的输入。
fn with_path_follow() -> &'static str {
    r#"{
      "nodes": {
        "root": { "inputs": { "nixpkgs": "nixpkgs", "child": "child", "data": false } },
        "nixpkgs": { "locked": { "type": "github", "rev": "aaa" } },
        "child": {
          "locked": { "type": "github", "rev": "ddd" },
          "inputs": { "nixpkgs-lib": ["nixpkgs"] }
        }
      },
      "root": "root"
    }"#
}

fn names(deps: &[NamedDep]) -> Vec<&str> {
    deps.iter().map(|dep| dep.name.as_str()).collect()
}

#[test]
fn follow_mode_dedupes_by_name() {
    let deps = parse(flake_lock(), "hjem", false).expect("应当可以解析");
    assert_eq!(names(&deps), vec!["flake-utils", "nixpkgs", "systems"]);

    let nixpkgs = deps
        .iter()
        .find(|dep| dep.name == "nixpkgs")
        .expect("应当有 nixpkgs");
    assert_eq!(nixpkgs.dep.ftype, "github");
    assert_eq!(nixpkgs.dep.locked["rev"], "aaa");
}

#[test]
fn isolate_mode_prefixes_the_path() {
    let deps = parse(flake_lock(), "hjem", true).expect("应当可以解析");
    assert_eq!(
        names(&deps),
        vec![
            "hjem/flake-utils",
            "hjem/flake-utils/systems",
            "hjem/nixpkgs"
        ]
    );
}

#[test]
fn path_form_follows_the_root_input() {
    let deps = parse(with_path_follow(), "hjem", true).expect("应当可以解析");
    // flake = false 的输入被跳过
    assert_eq!(
        names(&deps),
        vec!["hjem/child", "hjem/child/nixpkgs-lib", "hjem/nixpkgs"]
    );
    let followed = deps
        .iter()
        .find(|dep| dep.name == "hjem/child/nixpkgs-lib")
        .expect("应当有跟随的输入");
    assert_eq!(followed.dep.locked["rev"], "aaa");
}

#[test]
fn legacy_follows_object_still_works() {
    let text = with_path_follow()
        .replace(r#"["nixpkgs"]"#, r#"{ "follows": "nixpkgs" }"#);
    let deps = parse(&text, "hjem", true).expect("应当可以解析");
    let followed = deps
        .iter()
        .find(|dep| dep.name == "hjem/child/nixpkgs-lib")
        .expect("应当有跟随的输入");
    assert_eq!(followed.dep.locked["rev"], "aaa");
}

#[test]
fn unknown_input_values_are_skipped() {
    let text = r#"{
      "nodes": {
        "root": { "inputs": { "weird": 42, "nixpkgs": "nixpkgs" } },
        "nixpkgs": { "locked": { "type": "github", "rev": "aaa" } }
      },
      "root": "root"
    }"#;
    let deps = parse(text, "hjem", false).expect("应当可以解析");
    assert_eq!(names(&deps), vec!["nixpkgs"]);
}

#[test]
fn missing_root_is_an_error() {
    assert!(parse(r#"{ "nodes": {}, "root": "root" }"#, "x", false).is_err());
}

#[test]
fn empty_follows_path_is_skipped() {
    // 真实 flake.lock 里出现过 follows = "" 导致的 []
    let text = r#"{
      "nodes": {
        "root": { "inputs": { "child": "child", "nixpkgs": "nixpkgs" } },
        "nixpkgs": { "locked": { "type": "github", "rev": "aaa" } },
        "child": {
          "locked": { "type": "github", "rev": "ddd" },
          "inputs": { "self": [] }
        }
      },
      "root": "root"
    }"#;
    let deps = parse(text, "hjem", true).expect("应当可以解析");
    assert_eq!(names(&deps), vec!["hjem/child", "hjem/nixpkgs"]);
}

#[test]
fn follow_mode_does_not_let_a_locked_less_node_take_a_name() {
    // 先遇到的同名依赖没有锁定信息时，后面的不能因此被丢掉
    let text = r#"{
      "nodes": {
        "root": { "inputs": { "a": "a", "b": "b" } },
        "a": { "inputs": { "dep": "p" } },
        "p": { "inputs": {} },
        "b": { "inputs": { "dep": "q" } },
        "q": { "locked": { "type": "github", "rev": "qqq" } }
      },
      "root": "root"
    }"#;
    let deps = parse(text, "hjem", false).expect("应当可以解析");
    assert_eq!(names(&deps), vec!["dep"]);
    assert_eq!(deps[0].dep.locked["rev"], "qqq");
}

#[test]
fn dependencies_without_a_type_are_skipped() {
    let text = r#"{
      "nodes": {
        "root": { "inputs": { "odd": "odd" } },
        "odd": { "locked": { "rev": "aaa" } }
      },
      "root": "root"
    }"#;
    let deps = parse(text, "hjem", false).expect("应当可以解析");
    assert!(deps.is_empty());
}
