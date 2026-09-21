use anyhow::{Result, bail};

pub struct Parsed {
    pub action: Action,
}

pub enum Action {
    All,
    Lock,
    Module,
}

pub const HELP: &str = r#"
Actions:
  h, -h         Print help
  help, --help  Print help
  a, all        Init AIO temple
  l, lock       Init channels.{nix,lock}
  m, module     Init module.nix
"#;

pub fn parse(args: Vec<String>) -> Result<Parsed> {
    let (arg0, subcommand) = { (args[0].clone(), args[1].clone()) };

    if args.len() < 2 {
        println!("{} {} <Action>\n{}", arg0, subcommand, HELP);
        bail!("Missing Action")
    }

    let parsed = match args[2].as_str() {
        "a" | "all" => Parsed {
            action: Action::All,
        },

        "l" | "lock" => Parsed {
            action: Action::Lock,
        },

        "m" | "module" => Parsed {
            action: Action::Module,
        },

        "h" | "-h" => {
            println!("{} {} <Action>\n{}", arg0, subcommand, HELP);
            std::process::exit(0);
        }

        "help" | "--help" => {
            println!("{} {} <Action>\n{}", arg0, subcommand, HELP);
            std::process::exit(0);
        }

        _ => {
            println!("{} {} <Action>\n{}", arg0, subcommand, HELP);
            bail!("Undefined Action: {}", args[1].as_str())
        }
    };

    Ok(parsed)
}
