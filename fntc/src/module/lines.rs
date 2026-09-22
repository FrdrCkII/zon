use anyhow::{Result, anyhow, bail};
use std::collections::HashSet;

pub fn replace_imports(text: &str, key: &str) -> Result<(String, HashSet<String>)> {
    let mut out_lines = Vec::new();
    let mut deps: HashSet<String> = HashSet::new();
    let mut in_block = false;

    for line in text.lines() {
        if in_block {
            if matches_tokens(line, &["#", "@fntc", "m", "end"]) {
                in_block = false;
                continue;
            }

            let (indent, name, path) = parse_import_line(line)
                .map_err(|e| anyhow!("invalid @fntc m block line in '{}': {}: {}", key, line, e))?;

            out_lines.push(format!("{indent}{name} = _.\"{path}\";"));
            deps.insert(path);
            continue;
        }

        if matches_tokens(line, &["#", "@fntc", "m", "begin"]) {
            in_block = true;
            continue;
        }

        out_lines.push(line.to_owned());
    }

    if in_block {
        bail!("unclosed @fntc m block in '{}'", key);
    }

    Ok((out_lines.join("\n"), deps))
}

fn matches_tokens(line: &str, expected: &[&str]) -> bool {
    let mut tokens = line.split_whitespace();
    for e in expected {
        if tokens.next() != Some(*e) {
            return false;
        }
    }
    tokens.next().is_none()
}

pub fn parse_import_line(line: &str) -> Result<(String, String, String)> {
    let trimmed = line.trim();
    let indent_len = line.len() - line.trim_start().len();
    let indent = line[..indent_len].to_owned();

    let (name, rest) = trimmed
        .split_once('=')
        .ok_or_else(|| anyhow!("missing '='"))?;

    let name = name.trim();
    if name.is_empty() {
        bail!("missing import binding name");
    }
    if name.chars().any(|c| c.is_whitespace()) {
        bail!("invalid import binding name: {name}");
    }

    let mut tokens = rest.split_whitespace();

    expect_token(&mut tokens, "null;")?;
    expect_token(&mut tokens, "#")?;
    expect_token(&mut tokens, "@fntc")?;
    expect_token(&mut tokens, "m")?;
    expect_token(&mut tokens, "import")?;

    let path_token = tokens.next().ok_or_else(|| anyhow!("missing '<path>'"))?;

    let path = path_token
        .strip_prefix('<')
        .and_then(|s| s.strip_suffix('>'))
        .ok_or_else(|| anyhow!("expected '<path>', got: {path_token}"))?;

    if path.is_empty() {
        bail!("empty import path");
    }

    if let Some(extra) = tokens.next() {
        bail!("unexpected text after import: {extra}");
    }

    Ok((indent, name.to_owned(), path.to_owned()))
}

fn expect_token(tokens: &mut std::str::SplitWhitespace, expected: &str) -> Result<()> {
    match tokens.next() {
        Some(t) if t == expected => Ok(()),
        Some(t) => bail!("expected '{}', got: '{}'", expected, t),
        None => bail!("missing '{}'", expected),
    }
}
