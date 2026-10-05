//! 构造 Nix 表达式时用到的小工具。

/// 把字符串转义成 Nix 字符串字面量。
///
/// JSON 的转义规则和 Nix 不一样：JSON 不转义 `$`，而 Nix 会把它当字符串插值
/// （`"${x}"`）；JSON 的 `\uXXXX` 在 Nix 里也不是转义，会被当成字面量。所以
/// 凡是把外部字符串拼进 Nix 表达式的地方，都要用这个函数。
pub(crate) fn string_literal(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + 2);
    out.push('"');
    for c in text.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            '"' => out.push_str("\\\""),
            '$' => out.push_str("\\$"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            other => out.push(other),
        }
    }
    out.push('"');
    out
}

#[cfg(test)]
mod tests;
