use super::clap::Parsed;
use super::lines;
use anyhow::{Result, anyhow, bail};
use std::collections::{BTreeMap, HashMap};
use std::io::Write;
use std::path::PathBuf;
use std::process::{Command, Stdio};

pub fn load(modules: &mut HashMap<String, String>, parsed: &Parsed, key: String) -> Result<()> {
    if modules.contains_key(&key) {
        return Ok(());
    }

    let path = if key == "___" {
        &parsed.config
    } else {
        &find_file(parsed, &key)?
    };

    let content = std::fs::read_to_string(path)
        .map_err(|e| anyhow!("failed to read module file '{}': {}", path.display(), e))?;

    let (content, deps) = lines::replace_imports(&content, &key)?;

    modules.insert(key.to_owned(), content.to_owned());

    for dep in deps {
        load(modules, parsed, dep)?;
    }

    Ok(())
}

pub fn find_file(parsed: &Parsed, key: &str) -> Result<PathBuf> {
    let rel = if key.ends_with(".nix") {
        key.to_owned()
    } else {
        format!("{}.nix", key)
    };

    // 从数组末尾往前查找，最先找到的获胜。
    for dir in parsed.search.iter().rev() {
        let candidate = dir.join(&rel);
        if candidate.is_file() {
            return Ok(candidate);
        }
    }

    bail!("cannot find module file for import <{}>", key)
}

pub fn render(modules: HashMap<String, String>) -> String {
    let map = modules
        .into_iter()
        .collect::<BTreeMap<_, _>>()
        .into_iter()
        .map(|(key, content)| format!("\"{key}\" = \n{content};\n"))
        .collect::<String>();

    let res = format!("builtins.getAttr \"___\" ((f: (x: f (x x)) (x: f (x x))) (_: {{\n{map}}}))");
    nixfmt(&res).unwrap_or(res)
}

pub fn nixfmt(code: &str) -> Option<String> {
    let mut child = Command::new("nixfmt")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .ok()?;

    {
        let mut stdin = child.stdin.take()?;
        stdin.write_all(code.as_bytes()).ok()?;
    }

    let output = child.wait_with_output().ok()?;
    if !output.status.success() {
        return None;
    }

    String::from_utf8(output.stdout).ok()
}
