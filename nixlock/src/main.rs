use anyhow::{Result, anyhow};
use clap::{Parser, ValueEnum};
use log::{LevelFilter, Log, Metadata, Record};
use std::{fs::canonicalize, io::Write, path::PathBuf, process::Stdio};
use tokio::{process::Command, runtime::Builder, task::JoinHandle, task::spawn};

#[derive(Parser)]
#[command(name = "nixlock", version = "0.1.0", author = "FrdrCkII")]
struct Rd {
    #[arg(short = 'm', long = "mode", value_enum, default_value = "lock")]
    mode: Mode,
    #[arg(short = 'c', long = "config", default_value = "channels.nix")]
    config: PathBuf,
    /// Input to be updated (separated by spaces)
    #[arg(short = 'u', long = "update", default_value = "")]
    update: String,
    /// Increase log verbosity (can be used multiple times: -v, -vv, -vvv ...)
    #[arg(short = 'v', long = "verbose", action = clap::ArgAction::Count)]
    verbose: u8,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum Mode {
    Lock,
    Update,
}

struct Logger {
    max_level: LevelFilter,
}

impl Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= self.max_level
    }

    fn flush(&self) {
        std::io::stderr().flush().ok();
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let mut stderr = std::io::stderr().lock();
            writeln!(
                stderr,
                "{} [{}] {}",
                record.level(),
                record.target(),
                record.args()
            )
            .ok();
        }
    }
}

impl Logger {
    fn init(verbosity: u8) -> Result<()> {
        let level = match verbosity {
            0 => LevelFilter::Warn,
            1 => LevelFilter::Info,
            2 => LevelFilter::Debug,
            _ => LevelFilter::Trace,
        };
        let logger = Self { max_level: level };
        log::set_boxed_logger(Box::new(logger))?;
        log::set_max_level(level);
        Ok(())
    }
}

struct Pa {
    name: String,
    result: String,
}

impl Pa {
    fn new(name: String, result: String) -> Self {
        Pa { name, result }
    }

    fn to_nix_expr(&self) -> String {
        format!("{} = {};", self.name, self.result)
    }
}

struct Pas {
    name: String,
    pas: Vec<Pa>,
}

impl Pas {
    fn new(name: String, size: usize) -> Self {
        let s: Vec<Pa> = Vec::with_capacity(size);
        Pas { name, pas: s }
    }

    fn to_nix_expr(&self) -> String {
        let pas = self
            .pas
            .iter()
            .map(|pa| pa.to_nix_expr())
            .collect::<String>();
        format!("{} = {{{}}};", self.name, pas)
    }

    fn to_nix_args(&self, current: usize) -> String {
        let pas = self
            .pas
            .iter()
            .take(current)
            .map(|pa| pa.to_nix_expr())
            .collect::<String>();
        format!("{{{}}}", pas)
    }
}

async fn run(expr: String) -> Result<String> {
    let output = Command::new("nix")
        .arg("run")
        .arg("--impure")
        .arg("--expr")
        .arg(&expr)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()?
        .wait_with_output()
        .await?;
    if output.status.success() {
        Ok(std::str::from_utf8(&output.stdout)?
            .trim()
            .trim_start_matches('"')
            .trim_end_matches('"')
            .to_string())
    } else {
        log::debug!("nix cannot evaluate this expression:\n{}", &expr);
        Err(anyhow!(format!(
            "nix returned a non-zero exit code: {}",
            output.status
        )))
    }
}

async fn eval(expr: String) -> Result<String> {
    let output = Command::new("nix")
        .arg("eval")
        .arg("--impure")
        .arg("--raw")
        .arg("--expr")
        .arg(&expr)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()?
        .wait_with_output()
        .await?;
    if output.status.success() {
        Ok(std::str::from_utf8(&output.stdout)?
            .trim()
            .trim_start_matches('"')
            .trim_end_matches('"')
            .to_string())
    } else {
        log::debug!("nix cannot run this derivation:\n{}", &expr);
        Err(anyhow!(format!(
            "nix returned a non-zero exit code: {}",
            output.status
        )))
    }
}

async fn main_run(el: String, name: String) -> Result<Pas> {
    let mut nix_const_c = 0;
    let nix_const = eval(format!("{} eval.nllib.matchLen \"{}\"", el, name))
        .await?
        .parse::<u32>()?;
    let mut results = Pas::new(name.to_owned(), nix_const as usize);
    while nix_const > nix_const_c {
        let phase_name = eval(format!(
            "{} eval.nllib.matchPhaseName \"{}\" {}",
            el, name, nix_const_c
        ))
        .await?;
        let args = if nix_const_c == 0 {
            "{}"
        } else {
            &results.to_nix_args(nix_const_c as usize)
        };
        let is_eval: bool = eval(format!(
            "{} eval.nllib.matchPhaseIsEval \"{}\" {} ({})",
            el, name, nix_const_c, args
        ))
        .await?
        .parse::<bool>()?;
        let result = if is_eval {
            eval(format!(
                "{} eval.nllib.matchEval \"{}\" {} ({})",
                el, name, nix_const_c, args
            ))
            .await?
        } else {
            run(format!(
                "{} eval.nllib.matchRun \"{}\" {} ({})",
                el, name, nix_const_c, args
            ))
            .await?
        };
        log::info!("Get {}:{}:{}", name, phase_name, result);
        results.pas.push(Pa::new(phase_name, result));
        nix_const_c = nix_const_c + 1;
    }
    Ok(results)
}

async fn main_start() -> Result<()> {
    let rd = Rd::parse();
    let _ = Logger::init(rd.verbose)?;
    let el = match rd.mode {
        Mode::Lock => format!(
            "let nl = {}; eval = nl ((import {}) // {{__mode = \"lock\"; __update = [];}}); in",
            include_str!("nixlock.nix"),
            canonicalize(rd.config)?.display().to_string()
        ),
        Mode::Update => {
            if rd.update.is_empty() {
                format!(
                    "let nl = {}; eval = nl ((import {}) // {{__mode = \"update\"; __update = [];}}); in",
                    include_str!("nixlock.nix"),
                    canonicalize(rd.config)?.display().to_string()
                )
            } else {
                format!(
                    "let nl = {}; eval = nl ((import {}) // {{__mode = \"update\"; __update = [{}];}}); in",
                    include_str!("nixlock.nix"),
                    canonicalize(rd.config)?.display().to_string(),
                    rd.update
                        .split(' ')
                        .enumerate()
                        .map(|(_, s)| format!("\"{}\"", s))
                        .collect::<String>()
                )
            }
        }
    };
    let list: Vec<String> = eval(format!("{} eval.nllib.attrNames eval.inputs", el))
        .await?
        .split('"')
        .enumerate()
        .filter_map(|(i, s)| {
            if i % 2 == 1 {
                Some(s.to_string())
            } else {
                None
            }
        })
        .collect();
    let mut handles: Vec<JoinHandle<Result<Pas>>> = Vec::with_capacity(list.len());
    let mut results: Vec<String> = Vec::with_capacity(handles.len());
    for name in list.iter() {
        handles.push(spawn(main_run(el.clone(), name.to_owned())));
    }
    for handle in handles {
        let s = handle.await??.to_nix_expr();
        results.push(s);
    }
    let results: String = results.into_iter().collect();
    println!("{{{}}}", results);
    Ok(())
}

fn main() -> Result<()> {
    Builder::new_multi_thread()
        .enable_all()
        .build()?
        .block_on(main_start())
}
