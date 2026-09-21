use std::collections::HashSet;

use anyhow::{Result, anyhow, bail};

pub fn replace_imports(text: &str, key: &str) -> Result<(String, HashSet<String>)> {
    let mut out_lines = Vec::new();
    let mut deps: HashSet<String> = HashSet::new();
    let mut in_block = false;

    for line in text.lines() {
        if in_block {
            if line.trim() == "# @fntc m end" {
                in_block = false;
                continue;
            }

            let (indent, name, path) = parse_import_line(line)
                .map_err(|e| anyhow!("invalid @fntc m block line in '{}': {}: {}", key, line, e))?;

            out_lines.push(format!("{indent}{name} = _.\"{path}\";"));
            deps.insert(path);
            continue;
        }

        if line.trim() == "# @fntc m begin" {
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

    let rest = rest.trim_start();
    let rest = rest
        .strip_prefix("null;")
        .ok_or_else(|| anyhow!("missing 'null;'"))?;
    let rest = rest.trim_start();
    let rest = rest
        .strip_prefix("# @fntc m import <")
        .ok_or_else(|| anyhow!("missing '# @fntc m import <'"))?;

    let end = rest.find('>').ok_or_else(|| anyhow!("missing '>'"))?;

    let path = &rest[..end];
    if path.is_empty() {
        bail!("empty import path");
    }

    let after = rest[end + 1..].trim();
    if !after.is_empty() {
        bail!("unexpected text after import: {after}");
    }

    Ok((indent, name.to_owned(), path.to_owned()))
}
