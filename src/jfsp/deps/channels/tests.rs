//! [`super`] 的单元测试。

use super::*;

fn channels_lock() -> &'static str {
    r#"{
      "config": { "defaults": {} },
      "builtin": { "version": "1.1.1", "typesData": {} },
      "locked": {
        "top": {
          "hjem": {
            "ftype": "gitArchive",
            "locked": { "rev": "aaa", "locked": "sha256-x" }
          }
        },
        "deps": {
          "nixpkgs": {
            "ftype": "github",
            "locked": { "rev": "bbb" }
          }
        }
      }
    }"#
}

#[test]
fn top_and_deps_become_named_dependencies() {
    let deps = parse(channels_lock(), "demo", false).expect("应当可以解析");
    let names: Vec<&str> = deps.iter().map(|dep| dep.name.as_str()).collect();
    assert_eq!(names, vec!["hjem", "nixpkgs"]);

    let hjem = &deps[0];
    assert_eq!(hjem.dep.ftype, "gitArchive");
    assert_eq!(hjem.dep.locked["rev"], "aaa");
    assert_eq!(deps[1].dep.ftype, "github");
}

#[test]
fn isolate_mode_prefixes_names() {
    let deps = parse(channels_lock(), "demo", true).expect("应当可以解析");
    let names: Vec<&str> = deps.iter().map(|dep| dep.name.as_str()).collect();
    assert_eq!(names, vec!["demo/hjem", "demo/nixpkgs"]);
}

#[test]
fn missing_locked_section_yields_no_dependencies() {
    let deps = parse("{}", "demo", false).expect("应当可以解析");
    assert!(deps.is_empty());
}

#[test]
fn broken_entries_do_not_take_the_whole_file_down() {
    let text = r#"{
      "locked": {
        "top": {
          "good": { "ftype": "gitArchive", "locked": { "rev": "aaa" } },
          "notAnObject": { "locked": "oops" },
          "noLocked": { "ftype": "x" }
        },
        "deps": {
          "nixpkgs": {
            "ftype": "github",
            "locked": { "rev": "bbb", "lastModified": 123 }
          }
        }
      }
    }"#;

    let deps = parse(text, "demo", false).expect("应当可以解析");
    let names: Vec<&str> = deps.iter().map(|dep| dep.name.as_str()).collect();
    assert_eq!(names, vec!["good", "nixpkgs"]);
    // 非字符串字段原样复制，不会让整份文件失败
    assert_eq!(deps[1].dep.locked["lastModified"], 123);
}
