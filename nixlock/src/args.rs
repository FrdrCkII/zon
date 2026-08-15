use anyhow::{Result, bail};
use log::{LevelFilter, Log, Metadata, Record};
use std::{io::Write, path::PathBuf, path::absolute};

pub struct Args {
    pub update: Update,
    pub config: PathBuf,
    pub verbose: u8,
}

pub enum Update {
    Lock,
    List(Vec<String>),
}

struct Logger;
impl Log for Logger {
    fn enabled(&self, _: &Metadata) -> bool {
        true
    }

    fn flush(&self) {
        let _ = std::io::stderr().flush();
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let mut stderr = std::io::stderr().lock();
            writeln!(
                stderr,
                "{}:{} {}",
                record.level(),
                record.target(),
                record.args()
            )
            .ok();
        }
    }
}

enum Flag {
    None,
    Config,
    Update,
}

const HELP: &str = r#"
Usage: nixlock [OPTIONS]

Options:
  -h, --help             Print help
  -c, --config <CONFIG>  Set config file path (default: channels.nix)
  -u, --update <UPDATE>  Set items that need updating
  -v, -vv, ...           Set log visibility
"#;

pub fn parse() -> Result<Args> {
    let args = std::env::args();

    let mut result = Args {
        update: Update::Lock,
        config: absolute(PathBuf::from("channels.nix"))?,
        verbose: 0,
    };

    let mut flag = Flag::None;
    for arg in args.into_iter().skip(1) {
        // long flag
        if arg.starts_with("--") {
            match arg.as_str() {
                "--help" => {
                    println!("{HELP}");
                    std::process::exit(0);
                }

                "--config" => flag = Flag::Config,

                "--update" => {
                    flag = Flag::Update;
                    if matches!(result.update, Update::Lock) {
                        result.update = Update::List(Vec::new());
                    }
                }

                other => {
                    println!("{HELP}");
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
                        println!("{HELP}");
                        std::process::exit(0);
                    }

                    'v' => {
                        result.verbose += 1;
                    }

                    'c' => {
                        if i + 1 != chars.len() {
                            bail!("-c requires an argument, but found combined flags: {arg}");
                        }
                        flag = Flag::Config;
                    }

                    'u' => {
                        if i + 1 != chars.len() {
                            bail!("-u requires an argument, but found combined flags: {arg}");
                        }
                        flag = Flag::Update;
                        if matches!(result.update, Update::Lock) {
                            result.update = Update::List(Vec::new());
                        }
                    }

                    other => {
                        println!("{HELP}");
                        bail!("unknown short option: -{other}")
                    }
                }

                i += 1;
            }

            continue;
        }

        match flag {
            Flag::None => {
                println!("{HELP}");
                bail!("unexpected argument: {arg}");
            }

            Flag::Config => {
                result.config = absolute(PathBuf::from(&arg))?;
                flag = Flag::None;
            }

            Flag::Update => match result.update {
                Update::Lock => unreachable!(),
                Update::List(ref mut items) => items.push(arg),
            },
        }
    }

    log::set_boxed_logger(Box::new(Logger))?;
    log::set_max_level(match result.verbose {
        0 => LevelFilter::Error,
        1 => LevelFilter::Warn,
        2 => LevelFilter::Info,
        3 => LevelFilter::Debug,
        _ => LevelFilter::Trace,
    });

    Ok(result)
}
