use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(version, author, about, long_about = None)]
pub struct Args0 {
  #[arg(skip)]
  pub arg0: String,

  #[command(subcommand)]
  pub command: Commands,

  #[arg(skip)]
  pub args: Vec<String>,
}

#[derive(Subcommand)]
pub enum Commands {
  /// Lock Remote Nix Inputs
  #[command(visible_alias = "l")]
  Lock,
}

impl Args0 {
  pub fn parse0() -> Self {
    let mut args: Vec<String> = std::env::args().collect();

    let mut parsed = Self::parse_from(&args);

    let arg0 = args.remove(0);
    let args = args;

    parsed.arg0 = arg0;
    parsed.args = args;

    let parsed = parsed;
    parsed
  }
}
