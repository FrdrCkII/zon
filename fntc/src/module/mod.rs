pub mod clap;

pub mod lines;

use self::clap::Parsed;
use anyhow::{Result, anyhow, bail};
use std::collections::HashSet;
use std::path::{Path, PathBuf};

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

        let (content, deps) = lines::replace_imports(&text, &key)?;

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
            lines::render_attr(&mut out, key, content);
        }

        out.push_str("  })\n");
        out.push_str(")\n");

        out
    }
}

pub fn main(parsed: Parsed) -> Result<()> {
    let mut builder = Builder {
        search: &parsed.search,
        modules: Vec::new(),
        loaded: HashSet::new(),
        visiting: HashSet::new(),
    };

    builder.load("___".to_owned(), &parsed.config)?;

    let out = builder.render();
    std::fs::write(parsed.output, out)?;

    Ok(())
}
