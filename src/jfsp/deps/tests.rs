//! [`super`] 的单元测试。

use super::*;

fn fixture(name: &str, content: &str) -> std::path::PathBuf {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("target")
        .join(format!("fnlock-deps-{}", std::process::id()))
        .join(name);
    std::fs::create_dir_all(&dir).expect("应当可以建立测试目录");
    std::fs::write(dir.join("flake.lock"), content)
        .expect("应当可以写入 fixture");
    dir
}

#[test]
fn read_prefers_channels_lock_then_falls_back_to_flake_lock() {
    let flake = fixture(
        "flake-only",
        r#"{ "root": "root", "nodes": {
            "root": { "inputs": { "nixpkgs": "nixpkgs" } },
            "nixpkgs": { "locked": { "type": "github", "rev": "aaa" } }
        } }"#,
    );
    let deps = read(&flake, "hjem", false).expect("应当可以读取");
    assert_eq!(deps.len(), 1);
    assert_eq!(deps[0].name, "nixpkgs");

    std::fs::write(
        flake.join("channels.lock"),
        r#"{ "locked": { "top": {
            "agenix": { "ftype": "gitArchive", "locked": { "rev": "bbb" } }
        } } }"#,
    )
    .expect("应当可以写入 fixture");
    let deps = read(&flake, "hjem", false).expect("应当可以读取");
    assert_eq!(deps.len(), 1);
    assert_eq!(deps[0].name, "agenix");
    assert_eq!(deps[0].dep.ftype, "gitArchive");

    let _ = std::fs::remove_dir_all(flake);
}

#[test]
fn insert_dedupes_by_name() {
    let mut deps = HashMap::new();
    let dep = |ftype: &str| ItemDep {
        ftype: ftype.to_owned(),
        locked: serde_json::json!({ "rev": "aaa" }),
    };

    insert(
        &mut deps,
        NamedDep {
            name: "nixpkgs".to_owned(),
            dep: dep("github"),
        },
    );
    // 同名依赖只保留先出现的
    insert(
        &mut deps,
        NamedDep {
            name: "nixpkgs".to_owned(),
            dep: dep("git"),
        },
    );

    assert_eq!(deps.len(), 1);
    assert_eq!(deps["nixpkgs"].ftype, "github");
}
