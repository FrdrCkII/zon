//! [`super`] 的单元测试。

use super::*;

#[test]
fn string_literal_escapes_special_characters() {
    assert_eq!(string_literal("jq"), "\"jq\"");
    assert_eq!(string_literal(r#"a"b"#), r#""a\"b""#);
    assert_eq!(string_literal(r"a\b"), r#""a\\b""#);
    assert_eq!(string_literal("a\nb"), r#""a\nb""#);
}

#[test]
fn string_literal_stops_interpolation() {
    // 路径里带 ${...} 时，JSON 转义不会处理 `$`，Nix 却会去求值
    assert_eq!(string_literal("chan${x}.nix"), r#""chan\${x}.nix""#);
}
