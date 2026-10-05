//! [`super`] 的单元测试。

use super::*;

#[test]
fn builtin_defaults_keep_hash_type() {
    assert_eq!(Config::default().defaults["hashType"], "sha256");
    assert!(Config::default().auto_follow);
}

#[test]
fn defaults_in_file_override_builtin_ones() {
    let config: Config =
        serde_json::from_str(r#"{"defaults":{"hashType":"blake3"}}"#)
            .expect("应当可以解析");
    assert_eq!(config.defaults["hashType"], "blake3");
}

#[test]
fn defaults_accept_scalars_from_nix() {
    // nix 配置很自然地会写 false 或数字，不应该让整份配置求值失败
    let config: Config = serde_json::from_str(
        r#"{"defaults":{"unpack":false,"jobs":4,"name":"demo"}}"#,
    )
    .expect("应当可以解析");

    assert_eq!(config.defaults["unpack"], "false");
    assert_eq!(config.defaults["jobs"], "4");
    assert_eq!(config.defaults["name"], "demo");
}

#[test]
fn defaults_reject_structures() {
    let err = serde_json::from_str::<Config>(r#"{"defaults":{"bad":{"a":1}}}"#)
        .expect_err("结构不能当作字符串");
    assert!(err.to_string().contains("bad"), "{err}");
}
