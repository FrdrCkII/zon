pub mod clap;

use self::clap::Parsed;
use anyhow::{Result, anyhow, bail};
use std::collections::HashSet;
use std::path::{Path, PathBuf};

pub fn main(parsed: Parsed) -> Result<()> {
    let mut builder = Builder {
        search: &parsed.search,
        modules: Vec::new(),
        loaded: HashSet::new(),
        visiting: HashSet::new(),
    };

    builder.load("___".to_owned(), &parsed.config)?;

    let out = builder.render();
    std::fs::write("out.nix", out)?;

    Ok(())
}

struct Builder<'a> {
    search: &'a [PathBuf],
    modules: Vec<(String, String)>,
    loaded: HashSet<String>,
    visiting: HashSet<String>,
}

impl<'a> Builder<'a> {
    fn load(&mut self, key: String, path: &Path) -> Result<()> {
        if self.loaded.contains(&key) || self.visiting.contains(&key) {
            return Ok(());
        }

        let text = std::fs::read_to_string(path)
            .map_err(|e| anyhow!("failed to read module file '{}': {}", path.display(), e))?;

        let (content, deps) = replace_imports(&text, &key)?;

        self.visiting.insert(key.clone());

        for dep in deps {
            let dep_path = self.find_file(&dep)?;
            self.load(dep, &dep_path)?;
        }

        self.visiting.remove(&key);

        self.loaded.insert(key.clone());
        self.modules.push((key, content));

        Ok(())
    }

    fn find_file(&self, dep: &str) -> Result<PathBuf> {
        let rel = if dep.ends_with(".nix") {
            dep.to_owned()
        } else {
            format!("{dep}.nix")
        };

        // 从数组末尾往前查找，最先找到的获胜。
        for dir in self.search.iter().rev() {
            let candidate = dir.join(&rel);
            if candidate.is_file() {
                return Ok(candidate);
            }
        }

        bail!("cannot find module file for import <{}>", dep)
    }

    fn render(&self) -> String {
        let mut out = String::new();

        out.push_str("builtins.getAttr \"___\" (\n");
        out.push_str("  (f: (x: f (x x)) (x: f (x x))) (_: {\n");

        for (key, content) in &self.modules {
            render_attr(&mut out, key, content);
        }

        out.push_str("  })\n");
        out.push_str(")\n");

        out
    }
}

fn replace_imports(text: &str, key: &str) -> Result<(String, Vec<String>)> {
    let mut out_lines = Vec::new();
    let mut deps = Vec::new();
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
            deps.push(path);
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

fn parse_import_line(line: &str) -> Result<(String, String, String)> {
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

fn render_attr(out: &mut String, key: &str, content: &str) {
    let key = key.replace('\\', "\\\\").replace('"', "\\\"");

    let content = content.trim_end_matches('\n');
    let lines: Vec<&str> = content.lines().collect();

    if lines.is_empty() {
        out.push_str(&format!("    \"{key}\" = null;\n"));
        return;
    }

    if lines[0].trim_start().starts_with('{') {
        out.push_str(&format!("    \"{key}\" = {}\n", lines[0]));

        for line in &lines[1..] {
            out.push_str("    ");
            out.push_str(line);
            out.push('\n');
        }
    } else {
        out.push_str(&format!("    \"{key}\" =\n"));

        for line in &lines {
            out.push_str("      ");
            out.push_str(line);
            out.push('\n');
        }
    }

    if out.ends_with('\n') {
        out.pop();
    }

    out.push_str(";\n");
}
