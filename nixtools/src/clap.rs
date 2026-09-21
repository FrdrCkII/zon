use crate::build;
use crate::init;
use crate::lock;
use crate::module;
use anyhow::{Result, bail};

pub enum Parsed {
    Init(init::clap::Parsed),
    Lock(lock::clap::Parsed),
    Module(module::clap::Parsed),
    Build(build::clap::Parsed),
}

const HELP: &str = r#"
Commands:
  h, -h         Print help
  help, --help  Print help
  i, init       Init template file
  l, lock       Lock remote input
  b, build      Build remote input
  m, module     Compile a Nix project
"#;

pub fn parse() -> Result<Parsed> {
    let args = std::env::args().collect::<Vec<String>>();

    if args.len() < 2 {
        println!("{} <SUBCOMMAND> [OPTIONS]\n{}", args[0], HELP);
        bail!("Missing subcommand")
    }

    let parsed = match args[1].as_str() {
        "i" | "init" => Parsed::Init(init::clap::parse(args)?),
        "l" | "lock" => Parsed::Lock(lock::clap::parse(args)?),
        "b" | "build" => Parsed::Build(build::clap::parse(args)?),
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
