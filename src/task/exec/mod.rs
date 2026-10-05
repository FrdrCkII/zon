//! 命令管道的执行，以及命令所需的包环境。

use anyhow::{Context, Result, anyhow, bail};
use log::{debug, info};
use serde_json::Value;
use std::collections::HashSet;
use tokio::io::{self, AsyncReadExt};
use tokio::process::Command;

/// 管道最后一条命令输出的上限：这里的输出都是短文本，超过说明命令用错了。
const MAX_OUTPUT: u64 = 1 << 20;

/// 用 nixpkgs 构建命令任务所需的包环境，返回它的 store 路径。
///
/// 没有需要的包时返回 `Ok(None)`，此时命令沿用当前进程的环境。
pub(super) async fn build_env(
    packages: &HashSet<String>,
) -> Result<Option<String>> {
    if packages.is_empty() {
        return Ok(None);
    }

    let mut names: Vec<&str> = packages.iter().map(String::as_str).collect();
    names.sort_unstable();
    let names_nix = names
        .iter()
        .map(|name| crate::jfsp::nix::string_literal(name))
        .collect::<Vec<String>>()
        .join(" ");
    let expr = format!(
        concat!(
            "let pkgs = import <nixpkgs> {{}}; in pkgs.buildEnv {{ ",
            "name = \"fnlock-pkgs\"; ignoreCollisions = true; ",
            "paths = map (name: pkgs.${{name}}) [ {names} ]; }}",
        ),
        names = names_nix,
    );
    let joined = names.join(", ");
    info!("构建包环境（{joined}）：{expr}");

    let output = Command::new("nix")
        .args([
            "build",
            "--extra-experimental-features",
            "nix-command",
            "--impure",
            "--no-link",
            "--json",
            "--no-pretty",
            "--expr",
        ])
        .arg(&expr)
        .kill_on_drop(true)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .output()
        .await
        .context("无法执行 nix，请确认 nix 已安装并位于 PATH 中")?;

    if !output.status.success() {
        bail!("nix 无法构建命令所需的包环境（{joined}）：\n{expr}");
    }

    let stdout = String::from_utf8(output.stdout)
        .context("nix 的输出不是有效的 UTF-8")?;
    let builds: Vec<Value> = serde_json::from_str(&stdout)
        .with_context(|| format!("无法解析 nix 构建输出的 JSON：{stdout}"))?;
    let path = builds
        .first()
        .and_then(|build| build.get("outputs"))
        .and_then(|outputs| outputs.get("out"))
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow!("nix 构建结果缺少 [0].outputs.out：{stdout}"))?;

    Ok(Some(path.to_owned()))
}

/// 把包环境的 `bin` 目录放到 `PATH` 最前面；没有包环境时返回 `None`。
pub(super) fn path_with(env: Option<&str>) -> Option<String> {
    let env = env?;
    Some(match std::env::var("PATH") {
        Ok(current) if !current.is_empty() => format!("{env}/bin:{current}"),
        _ => format!("{env}/bin"),
    })
}

/// 顺序执行一个简单管道，返回最后一条命令的标准输出（去掉首尾空白）。
///
/// `env_path` 存在时作为命令的 `PATH`（包环境的 `bin` 在最前面），
/// 否则直接继承当前进程的环境。
pub(super) async fn pipeline(
    stages: &[Vec<String>],
    env_path: Option<&str>,
) -> Result<String> {
    if stages.is_empty() {
        bail!("命令管道不能为空");
    }

    let mut children = Vec::with_capacity(stages.len());
    for (index, argv) in stages.iter().enumerate() {
        let (program, args) = argv
            .split_first()
            .ok_or_else(|| anyhow!("第 {index} 条命令为空"))?;

        let mut child = Command::new(program);
        child
            .args(args)
            .stdin(if index == 0 {
                std::process::Stdio::null()
            } else {
                std::process::Stdio::piped()
            })
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::inherit())
            .kill_on_drop(true);
        if let Some(path) = env_path {
            child.env("PATH", path);
        }

        children.push(child.spawn().with_context(|| {
            format!("无法启动第 {index} 条命令 '{program}'")
        })?);
    }

    let mut stdout_handles = Vec::with_capacity(children.len());
    let mut stdin_handles = Vec::with_capacity(children.len());
    for child in &mut children {
        stdout_handles.push(child.stdout.take());
        stdin_handles.push(child.stdin.take());
    }

    // 相邻进程之间复制标准输出/标准输入
    let mut copies = Vec::with_capacity(children.len().saturating_sub(1));
    for index in 0..children.len() - 1 {
        let mut stdout = stdout_handles[index]
            .take()
            .ok_or_else(|| anyhow!("第 {index} 条命令缺少标准输出"))?;
        let mut stdin = stdin_handles[index + 1]
            .take()
            .ok_or_else(|| anyhow!("第 {} 条命令缺少标准输入", index + 1))?;
        copies.push(tokio::spawn(async move {
            io::copy(&mut stdout, &mut stdin).await.map(|_| ())
        }));
    }

    let last_stdout = stdout_handles
        .last_mut()
        .and_then(Option::take)
        .ok_or_else(|| anyhow!("最后一条命令缺少标准输出"))?;
    let mut raw = Vec::new();
    last_stdout
        .take(MAX_OUTPUT + 1)
        .read_to_end(&mut raw)
        .await
        .context("无法读取最后一条命令的标准输出")?;
    if raw.len() as u64 > MAX_OUTPUT {
        bail!("最后一条命令的输出超过 {MAX_OUTPUT} 字节，拒绝读入");
    }
    let output = String::from_utf8(raw)
        .context("最后一条命令的输出不是有效的 UTF-8")?
        .trim()
        .to_owned();

    // 进程的退出状态才是判据，复制任务的结果可以忽略
    for copy in copies {
        let _ = copy.await;
    }

    // 只把最后一条命令的失败当致命错误：上游常常是因为下游提前退出
    // （`head -n1` 读够就关掉管道）而拿到 EPIPE 才非零退出的，这属于管道
    // 正常结束的一部分。但如果整条管道什么也没输出，那更可能是真的失败。
    let mut early: Option<(usize, std::process::ExitStatus)> = None;
    for (index, mut child) in children.into_iter().enumerate() {
        let status = child
            .wait()
            .await
            .with_context(|| format!("无法等待第 {index} 条命令"))?;
        if status.success() {
            continue;
        }
        if index + 1 == stages.len() {
            bail!(
                "最后一条命令退出状态为 {status}：{}",
                stages[index].join(" ")
            );
        }
        early = early.or(Some((index, status)));
    }

    if let Some((index, status)) = early {
        if output.is_empty() {
            bail!(
                "第 {index} 条命令退出状态为 {status}，管道也没有输出：{}",
                stages[index].join(" ")
            );
        }
        debug!(
            "第 {index} 条命令提前结束（{status}），视为下游已停止读取：{}",
            stages[index].join(" ")
        );
    }

    Ok(output)
}

#[cfg(test)]
mod tests;
