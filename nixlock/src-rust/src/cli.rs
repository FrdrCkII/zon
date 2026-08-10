use anyhow::{Result, bail};
use indicatif::MultiProgress;
use log::{LevelFilter, Log, Metadata, Record};
use std::{io::Write, path::PathBuf, path::absolute, sync::Arc};

pub struct Args {
    pub update: Update,
    pub config: String,
    pub nixpath: String,
    pub mainexpr: String,
    pub progress: Arc<MultiProgress>,
    pub verbose: u8,
}

pub enum Update {
    Lock,
    List(Vec<String>),
}

impl Update {
    fn to_str(&self) -> String {
        match self {
            Self::Lock => "null".to_string(),
            Self::List(list) => {
                let update_str = list
                    .into_iter()
                    .map(|s| format!("\"{s}\""))
                    .collect::<Vec<_>>()
                    .join(" ");
                format!("[{update_str}]")
            }
        }
    }
}

struct Logger {
    progress: Arc<MultiProgress>,
}

impl Log for Logger {
    fn enabled(&self, _: &Metadata) -> bool {
        true
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let msg = format!("{}:{} {}", record.level(), record.target(), record.args());
            self.progress.suspend(|| {
                eprintln!("{}", msg);
            });
        }
    }

    fn flush(&self) {
        let _ = std::io::stderr().flush();
    }
}

impl Args {
    fn log(&self) -> Result<()> {
        let level = match self.verbose {
            0 => LevelFilter::Warn,
            1 => LevelFilter::Info,
            2 => LevelFilter::Debug,
            _ => LevelFilter::Trace,
        };

        let logger = Logger {
            progress: Arc::clone(&self.progress),
        };

        log::set_boxed_logger(Box::new(logger))?;
        log::set_max_level(level);

        Ok(())
    }

    pub fn parse() -> Result<Self> {
        enum Flag {
            None,
            Config,
            Update,
        }

        const HELP: &str = r#"
Usage: nixlock [OPTIONS]

-h, --help               |  print help info
-c, --config [path]      |  config file path (default: channels.nix)
-u, --update [name,...]  |  items that need updating
-v, -vv, ...             |  set log visibility
        "#;

        let args = std::env::args();

        let mut result = Self {
            update: Update::Lock,
            config: absolute(PathBuf::from("channels.nix"))?
                .to_str()
                .unwrap()
                .to_string(),
            nixpath: absolute(PathBuf::from(&std::env::var("NIXLOCK_NIX_PATH")?))?
                .to_str()
                .unwrap()
                .to_string(),
            mainexpr: String::new(),
            progress: Arc::new(MultiProgress::new()),
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
                    result.config = absolute(PathBuf::from(&arg))?.to_str().unwrap().to_string();
                    flag = Flag::None;
                }

                Flag::Update => match result.update {
                    Update::Lock => unreachable!(),
                    Update::List(ref mut items) => items.push(arg),
                },
            }
        }

        result.mainexpr = format!(
            r#"let el = import "{}" (import "{}") {{ update = {}; }}; in "#,
            &result.nixpath,
            &result.config,
            &result.update.to_str()
        );

        let result = result;
        result.log()?;

        Ok(result)
    }
}
