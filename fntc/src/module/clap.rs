use anyhow::{Result, bail};
use std::{path::PathBuf, path::absolute};

pub struct Parsed {
    pub config: PathBuf,
    pub search: Vec<PathBuf>,
    pub output: PathBuf,
}

pub const HELP: &str = r#"
Options:
  -h, --help             Print help
  -c, --config <CONFIG>  Set config file path (default: main.nix)
  -d, --search-dirs <PATH> ...  Add extra module search paths
                         (The config file location will be added automatically)
  -o, --output <PATH>    Output path (default: out.nix)
"#;

enum Flag {
    None,
    Config,
    Search,
    Output,
}

pub fn parse(args: Vec<String>) -> Result<Parsed> {
    let (arg0, subcommand, mut flag, mut parsed) = {
        (
            args[0].clone(),
            args[1].clone(),
            Flag::None,
            Parsed {
                search: Vec::new(),
                config: absolute(PathBuf::from("main.nix"))?,
                output: absolute(PathBuf::from("out.nix"))?,
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
                }

                "--config" => flag = Flag::Config,

                "--search-dirs" => flag = Flag::Search,

                "--output" => flag = Flag::Output,

                other => {
                    println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
                    bail!("unknown long option: {other}")
                }
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
                    }

                    'c' => {
                        if i + 1 != chars.len() {
                            bail!("-c requires an argument, but found combined flags: {arg}");
                        }
                        flag = Flag::Config;
                    }

                    'o' => {
                        if i + 1 != chars.len() {
                            bail!("-c requires an argument, but found combined flags: {arg}");
                        }
                        flag = Flag::Output;
                    }

                    'd' => {
                        if i + 1 != chars.len() {
                            bail!("-d requires an argument, but found combined flags: {arg}");
                        }
                        flag = Flag::Search;
                    }

                    other => {
                        println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
                        bail!("unknown short option: -{other}")
                    }
                }

                i += 1;
            }

            continue;
        }

        match flag {
            Flag::None => {
                println!("{} {} [OPTIONS]\n{}", arg0, subcommand, HELP);
                bail!("unexpected argument: {arg}");
            }

            Flag::Config => {
                parsed.config = absolute(PathBuf::from(&arg))?;
                flag = Flag::None;
            }

            Flag::Search => {
                parsed.search.push(absolute(PathBuf::from(&arg))?);
            }

            Flag::Output => {
                parsed.output = absolute(PathBuf::from(&arg))?;
                flag = Flag::None;
            }
        }
    }

    if let Some(parent) = parsed.config.parent() {
        parsed.search.push(parent.to_path_buf());
    } else {
        parsed.search.push(absolute(PathBuf::from("."))?);
    }

    Ok(parsed)
}
