use crate::lock;
use crate::module;
use anyhow::{Result, bail};

pub enum Parsed {
    Lock(lock::clap::Parsed),
    Module(module::clap::Parsed),
}

const HELP: &str = r#"
Commands:
  h, -h         Print help
  help, --help  Print help
  l, lock       Lock remote input
  m, module     Compile a Nix project
"#;

pub fn parse() -> Result<Parsed> {
    let args = std::env::args().collect::<Vec<String>>();

    if args.len() < 2 {
        println!("{} <SUBCOMMAND> [OPTIONS]\n{}", args[0], HELP);
        bail!("Missing subcommand")
    }

    let parsed = match args[1].as_str() {
        "l" | "lock" => Parsed::Lock(lock::clap::parse(args)?),
        "m" | "module" => Parsed::Module(module::clap::parse(args)?),

        "h" | "-h" => {
            println!("{} <SUBCOMMAND> [OPTIONS]\n{}", args[0], HELP);
            std::process::exit(0);
        }

        "help" | "--help" => {
            println!("{} <SUBCOMMAND> [OPTIONS]\n{}", args[0], HELP);
            std::process::exit(0);
        }

        _ => {
            println!("{} <SUBCOMMAND> [OPTIONS]\n{}", args[0], HELP);
            bail!("Undefined Subcommand: {}", args[1].as_str())
        }
    };

    Ok(parsed)
}
