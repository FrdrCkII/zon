use anyhow::{Result, bail};
use std::{path::PathBuf, path::absolute};

pub struct Parsed {
  pub update: Update,
  pub config: PathBuf,
  pub recursion: bool,
  pub follow: bool,
}

pub enum Update {
  Lock,
  List(Vec<String>),
}

pub const HELP: &str = r#"
Options:
  -h, --help             Print help
  -c, --config <CONFIG>  Set config file path (default: channels.nix)
  -u, --update <UPDATE>  Set items that need updating
  -r, --no-rec           Don't fetch dependencies recursively
  -f, --follow           Automatically deduplicate dependencies based on their names
"#;

enum Flag {
  None,
  Config,
  Update,
}

pub fn parse(args: Vec<String>) -> Result<Parsed> {
  let (arg0, subcommand, mut flag, mut parsed) = {
    (
      args[0].clone(),
      args[1].clone(),
      Flag::None,
      Parsed {
        update: Update::Lock,
        config: absolute(PathBuf::from("channels.nix"))?,
        recursion: true,
        follow: true,
      },
    )
  };

  for arg in args.into_iter().skip(2) {
    // long flag
    if arg.starts_with("--") {
      match arg.as_str() {
        "--help" => {
          println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
          std::process::exit(0);
        },

        "--config" => flag = Flag::Config,

        "--update" => {
          flag = Flag::Update;
          if matches!(parsed.update, Update::Lock) {
            parsed.update = Update::List(Vec::new());
          }
        },

        "--no-rec" => parsed.recursion = false,

        "--follow" => parsed.follow = true,

        other => {
          println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
          bail!("unknown long option: {other}")
        },
      }

      continue;
    }

    // short flag
    if arg.starts_with('-') && arg.len() > 1 {
      let chars: Vec<char> = arg.chars().skip(1).collect();
      let mut i = 0;
      while i < chars.len() {
        match chars[i] {
          'h' => {
            println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
            std::process::exit(0);
          },

          'c' => {
            if i + 1 != chars.len() {
              bail!("-c requires an argument, but found combined flags: {arg}");
            }
            flag = Flag::Config;
          },

          'u' => {
            if i + 1 != chars.len() {
              bail!("-u requires an argument, but found combined flags: {arg}");
            }
            flag = Flag::Update;
            if matches!(parsed.update, Update::Lock) {
              parsed.update = Update::List(Vec::new());
            }
          },

          'r' => parsed.recursion = false,

          'f' => parsed.follow = true,

          other => {
            println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
            bail!("unknown short option: -{other}")
          },
        }

        i += 1;
      }

      continue;
    }

    match flag {
      Flag::None => {
        println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
        bail!("unexpected argument: {arg}");
      },

      Flag::Config => {
        parsed.config = absolute(PathBuf::from(&arg))?;
        flag = Flag::None;
      },

      Flag::Update => match parsed.update {
        Update::Lock => unreachable!(),
        Update::List(ref mut items) => items.push(arg),
      },
    }
  }

  Ok(parsed)
}
