mod clap;
mod files;
mod lines;

use anyhow::Result;
use std::collections::HashMap;

pub fn run(args: Vec<String>) -> Result<()> {
  let parsed = clap::parse(args)?;

  let mut modules: HashMap<String, String> = HashMap::new();
  files::load(&mut modules, &parsed, "___".to_string())?;
  let res = files::render(modules);

  std::fs::write(parsed.output, res)?;

  Ok(())
}
