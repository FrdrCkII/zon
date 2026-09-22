pub mod clap;

pub mod files;
pub mod lines;

use self::clap::Parsed;
use anyhow::Result;
use std::collections::HashMap;

pub fn main(parsed: Parsed) -> Result<()> {
  let mut modules: HashMap<String, String> = HashMap::new();

  files::load(&mut modules, &parsed, "___".to_string())?;

  let res = files::render(modules);

  std::fs::write(parsed.output, res)?;

  Ok(())
}
