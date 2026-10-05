//! [`super`] 的单元测试。

use super::*;

#[test]
fn lock_files_round_trip_through_json() {
    let text = r#"{
        "config": { "defaults": { "hashType": "sha256" } },
        "builtin": {
            "version": "1.1.1",
            "typesData": {
                "gitArchive": {
                    "packages": ["git"],
                    "tasks": {
                        "rev": { "commands": [["git", "ls-remote", "{repo}"]] }
                    }
                }
            }
        },
        "locked": {
            "top": {
                "hjem": { "ftype": "gitArchive", "locked": { "rev": "abc" } }
            },
            "deps": {
                "nixpkgs": {
                    "ftype": "github",
                    "locked": { "owner": "NixOS", "rev": "def" }
                }
            }
        }
    }"#;

    let lock: Lock = serde_json::from_str(text).expect("应当可以解析");
    // 缺省的 group 会补成默认分组
    assert_eq!(lock.locked.top["hjem"].group, "default");
    assert_eq!(lock.locked.deps["nixpkgs"].ftype, "github");
    assert_eq!(lock.locked.deps["nixpkgs"].locked["rev"], "def");

    let text = serde_json::to_string(&lock).expect("应当可以序列化");
    let again: Lock = serde_json::from_str(&text).expect("应当可以再次解析");
    assert_eq!(again.locked, lock.locked);
}
