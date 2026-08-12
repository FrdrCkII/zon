use crate::cli::Args;
use anyhow::{Result, bail};
use indicatif::{ProgressBar, ProgressStyle};
use serde_json::Value;
use std::{process::Stdio, sync::Arc};
use tokio::{io::AsyncBufReadExt, process::Command, task::JoinHandle};

mod cli;

fn main() -> Result<()> {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?
        .block_on(async_main())
}

async fn async_main() -> Result<()> {
    let args = Arc::new(Args::parse()?);
    let el = &args.mainexpr;

    let names: Vec<String> = nix_eval(&format!("{el} el.list",))
        .await?
        .to_str()?
        .split(';')
        .filter(|s| !s.is_empty())
        .map(|s| s.to_owned())
        .collect::<Vec<String>>();

    let handles: Vec<JoinHandle<Result<String>>> = names
        .into_iter()
        .map(|name| {
            let args = Arc::clone(&args);
            let pb = args.progress.add(ProgressBar::new(100));
            tokio::spawn(async move { tasks_main(args, pb, name).await })
        })
        .collect();

    let mut results = Vec::with_capacity(handles.len());

    for handle in handles {
        results.push(handle.await??);
    }

    let output = results.into_iter().collect::<String>();
    println!("\n{{{output}}}");

    Ok(())
}

async fn tasks_main(args: Arc<Args>, pb: ProgressBar, name: String) -> Result<String> {
    log::trace!("task {name} start");
    
    let el = &args.mainexpr;
    log::trace!("task {name} el ready: {el}");

    pb.set_style(
        ProgressStyle::default_bar()
            .template("{prefix} {msg}")
            .unwrap(),
    );
    pb.set_prefix(format!("{name}"));
    log::trace!("task {name} pb ready");

    let total_phases: u32 = nix_eval(&format!("{el} el.nllib.matchLen \"{}\"", &name))
        .await?
        .to_str()?
        .parse::<u32>()?;
    log::trace!("task {name} get phases lens: {total_phases}");

    let mut parts = Vec::with_capacity(total_phases as usize);
    let mut current_args = String::new();

    for i in 0..total_phases {
        let phase_name = nix_eval(&format!("{el} el.nllib.matchPhaseName \"{}\" {i}", &name))
            .await?
            .to_str()?;
        
        log::trace!("task {name} phase {phase_name} start");
        pb.set_message(format!("[{}/{total_phases}]:{phase_name}", i + 1));

        let eval_args = if i == 0 {
            "{}".to_owned()
        } else {
            format!("({{{current_args}}})")
        };

        let mut result = nix_eval(&format!(
            "{el} el.nllib.matchEval \"{name}\" {i} {eval_args}",
        ))
            .await?;
        
        log::trace!("task {name} phase {phase_name} get result: {result:?}");

        loop {
            match result {
                EvalResult::Derivation => {
                    log::trace!("task {name} phase {phase_name} result match Derivation");
                    
                    result = nix_run(&format!(
                        "{el} el.nllib.matchRun \"{}\" {i} {eval_args}",
                        &name
                    ))
                        .await?;
                    
                    log::trace!("task {name} phase {phase_name} run derivation result: {result:?}");
                }

                EvalResult::Text(result) => {
                    log::trace!("task {name} phase {phase_name} result match Text");
                    log::info!("Get {}:{}:{}", name, phase_name, result);
                    
                    let pa_expr = format!("{phase_name} = {result};");

                    parts.push(pa_expr.clone());
                    if !current_args.is_empty() {
                        current_args.push(' ');
                    }
                    current_args.push_str(&pa_expr);

                    break;
                }

                EvalResult::Json(result) => {
                    log::trace!("task {name} phase {phase_name} result match json Value");
                    
                    let result_type = result["type"].as_str().unwrap();
                    let result_value = &result["value"];
                    match result_type {
                        "fetch" => {
                            log::trace!("task {name} phase {phase_name} prefetch start");
                            
                            let prefetch = nix_fetch(pb.to_owned(), result_value).await?;
                            log::trace!("task {name} phase {phase_name} prefetch result: {prefetch}");
                            
                            let pa_expr = format!("{phase_name} = {prefetch};");

                            parts.push(pa_expr.clone());
                            if !current_args.is_empty() {
                                current_args.push(' ');
                            }
                            current_args.push_str(&pa_expr);
                        }

                        _ => {}
                    }

                    break;
                }
            }
        }
    }

    log::trace!("task {name} finish");
    pb.finish_and_clear();

    let inner = parts.join("");
    Ok(format!("{name} = {{ {inner} }};"))
}

#[derive(Debug)]
enum EvalResult {
    Text(String),
    Json(Value),
    Derivation,
}

impl EvalResult {
    fn to_str(&self) -> Result<String> {
        match self {
            Self::Text(str) => Ok(str.to_owned()),
            _ => bail!(""),
        }
    }
}

async fn nix_eval(expr: &str) -> Result<EvalResult> {
    let child = Command::new("nix")
        .arg("eval")
        .arg("--extra-experimental-features")
        .arg("nix-command")
        .arg("--impure")
        .arg("--raw")
        .arg("--expr")
        .arg(expr)
        .kill_on_drop(true)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?
        .wait_with_output()
        .await?;

    if child.status.success() {
        let stdout = std::str::from_utf8(&child.stdout)?.trim().trim_matches('"');

        for line in stdout.lines() {
            if let Some(head) = line.strip_prefix("@nixlock;") {
                if let Some(_) = head.strip_prefix("@isDerivation;") {
                    return Ok(EvalResult::Derivation);
                } else if let Some(json_str) = head.strip_prefix("@isJSON;") {
                    if let Ok(value) = serde_json::from_str::<Value>(json_str) {
                        return Ok(EvalResult::Json(value));
                    }
                } else if let Some(raw_str) = head.strip_prefix("@isString;") {
                    return Ok(EvalResult::Text(raw_str.to_owned()));
                }

                bail!("cannot find any recognizable output");
            }
        }

        return Ok(EvalResult::Text(stdout.to_owned()));
    }

    log::error!("{}", std::str::from_utf8(&child.stdout)?);
    log::debug!("nix eval cannot evaluate this expression:\n{}", expr);
    bail!("nix returned a non-zero exit code: {}", child.status);
}

async fn nix_run(expr: &str) -> Result<EvalResult> {
    let child = Command::new("nix")
        .arg("run")
        .arg("--extra-experimental-features")
        .arg("nix-command")
        .arg("--impure")
        .arg("--expr")
        .arg(expr)
        .kill_on_drop(true)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?
        .wait_with_output()
        .await?;

    if child.status.success() {
        let stdout = std::str::from_utf8(&child.stdout)?.trim().trim_matches('"');

        for line in stdout.lines() {
            if let Some(head) = line.strip_prefix("@nixlock;") {
                if let Some(json_str) = head.strip_prefix("@isJSON;") {
                    if let Ok(value) = serde_json::from_str::<Value>(json_str) {
                        return Ok(EvalResult::Json(value));
                    }
                } else if let Some(raw_str) = head.strip_prefix("@isString;") {
                    return Ok(EvalResult::Text(raw_str.to_owned()));
                }
            }
        }

        return Ok(EvalResult::Text(stdout.to_owned()));
    }

    log::error!("{}", std::str::from_utf8(&child.stdout)?);
    log::debug!("nix eval cannot evaluate this expression:\n{}", expr);
    bail!("nix returned a non-zero exit code: {}", child.status);
}

async fn nix_fetch(pb: ProgressBar, value: &Value) -> Result<String> {
    let url = value["url"].as_str().unwrap();
    let hash = value["hash"].as_str().unwrap();
    let unpack = value["unpack"].as_bool().unwrap();

    let mut child = Command::new("nix");
    child
        .arg("store")
        .arg("prefetch-file")
        .arg("--extra-experimental-features")
        .arg("nix-command")
        .arg("--name")
        .arg("source")
        .arg("--hash-type")
        .arg(hash)
        .arg("--json")
        .arg("--no-pretty")
        .arg("--log-format")
        .arg("internal-json");
    if unpack {
        child.arg("--unpack");
    }
    let mut child = child
        .arg(url)
        .kill_on_drop(true)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    let stderr = child.stderr.take().unwrap();
    let stderr_reader = tokio::io::BufReader::new(stderr);
    let mut stderr_lines = stderr_reader.lines();

    let status_future = child.wait_with_output();

    enum PbSty {
        None,
        DWN,
        BAR,
    }

    let sty_none = ProgressStyle::default_bar().template("{prefix} {msg}")?;
    let sty_dwn = ProgressStyle::default_bar().template("{prefix} {msg} {bytes}")?;
    let sty_bar = ProgressStyle::default_bar()
        .template("{prefix} {msg} {bytes}/{total_bytes} [{wide_bar}]")?;

    let parse_handle = tokio::spawn(async move {
        let mut pb_sty = PbSty::None;

        while let Ok(Some(line)) = stderr_lines.next_line().await {
            if let Some(json_str) = line.strip_prefix("@nix ") {
                if let Ok(value) = serde_json::from_str::<Value>(json_str) {
                    if let Some(act) = value["action"].as_str() {
                        match act {
                            "result" => {
                                if let Some(fields) = value["fields"].as_array() {
                                    if fields.len() >= 2 {
                                        if let (Some(done), Some(total)) =
                                            (fields[0].as_u64(), fields[1].as_u64())
                                        {
                                            match (done, total) {
                                                (0, 0) => {}

                                                (_, 0) => {
                                                    match pb_sty {
                                                        PbSty::DWN => {}
                                                        _ => {
                                                            pb.set_style(sty_dwn.to_owned());
                                                            pb_sty = PbSty::DWN;
                                                        }
                                                    };

                                                    pb.set_position(done);
                                                }

                                                (_, _) => {
                                                    match pb_sty {
                                                        PbSty::BAR => {}
                                                        _ => {
                                                            pb.set_style(sty_bar.to_owned());
                                                            pb_sty = PbSty::BAR;
                                                        }
                                                    };

                                                    pb.set_length(total);
                                                    pb.set_position(done);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            "stop" => {
                                pb.set_style(sty_none.to_owned());
                            }

                            _ => {} // 忽略其他类型
                        }
                    }
                }
            }
        }
    });

    let child = status_future.await?;
    parse_handle.await?;

    if child.status.success() {
        let stdout = std::str::from_utf8(&child.stdout)?.trim().trim_matches('"');

        if let Ok(value) = serde_json::from_str::<Value>(stdout) {
            if let Some(hash) = value["hash"].as_str() {
                let result = format!("{{ url = \"{url}\"; hash = \"{hash}\"; }}");
                return Ok(result);
            }
        }

        log::error!("{}", std::str::from_utf8(&child.stdout)?);
        bail!("cannot find any recognizable output");
    }

    bail!("nix returned a non-zero exit code: {}", child.status);
}
