pub mod commands;
pub mod parse;

use crate::parse::{Args0, Commands};
use anyhow::Result;

fn main() -> Result<()> {
  let args = Args0::parse0();

  match args.command {
    Commands::Lock => commands::lock::run(args),
  }
}
