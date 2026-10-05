//! 配置文件读取：json 直接反序列化，其余交给 `nix eval`。

use super::ConfigFile;
use anyhow::{Context, Result, bail};
use log::info;
use std::path::Path;
use tokio::process::Command;

/// 读取并求值配置文件。
///
/// 配置里的类型保持原样（内置简写不展开），运行任务时再展开。
pub async fn load(path: &Path) -> Result<ConfigFile> {
    if !path.exists() {
        bail!("配置文件不存在：{}", path.display());
    }

    if is_json(path) {
        load_json(path)
    } else {
        eval_nix(path).await
    }
}

/// 是否是 json 配置文件（其余一律交给 nix 求值）。
fn is_json(path: &Path) -> bool {
    path.extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("json"))
}

/// 直接反序列化 json 配置文件。
fn load_json(path: &Path) -> Result<ConfigFile> {
    let text = std::fs::read_to_string(path)
        .with_context(|| format!("无法读取配置文件：{}", path.display()))?;
    serde_json::from_str(&text)
        .with_context(|| format!("配置文件格式不正确：{}", path.display()))
}

/// 用 `nix eval` 求值 nix 配置文件。
async fn eval_nix(path: &Path) -> Result<ConfigFile> {
    // nix 的 import 需要绝对路径；拼进表达式时要用 Nix 自己的转义规则
    let path = std::path::absolute(path)
        .with_context(|| format!("无法解析配置文件路径：{}", path.display()))?;
    let expr = format!(
        concat!(
            "let c = import {path}; in ",
            "if !builtins.isAttrs c then throw \"配置文件必须求值为属性集\" else ",
            "{{ inputs = if (c.inputs or null) == null then {{}} else c.inputs; ",
            "config = c.config or null; }}",
        ),
        path =
            crate::jfsp::nix::string_literal(path.to_string_lossy().as_ref()),
    );
    info!("执行 nix eval：{expr}");

    let output = Command::new("nix")
        .args([
            "eval",
            "--extra-experimental-features",
            "nix-command",
            "--impure",
            "--json",
            "--no-pretty",
            "--expr",
        ])
        .arg(&expr)
        .kill_on_drop(true)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .output()
        .await
        .context("无法执行 nix，请确认 nix 已安装并位于 PATH 中")?;

    if !output.status.success() {
        // nix 的原因只在 stderr 里，必须带进错误信息
        bail!(
            "nix 无法求值配置文件：{}\n{}",
            path.display(),
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }

    let stdout = String::from_utf8(output.stdout)
        .context("nix 的输出不是有效的 UTF-8")?;
    let stdout = stdout.trim();
    serde_json::from_str(stdout).with_context(|| {
        format!("无法解析 nix 输出的 JSON：{}", truncate(stdout))
    })
}

/// 截断过长文本，避免把整份 JSON 塞进错误信息。
fn truncate(text: &str) -> String {
    const LIMIT: usize = 200;
    if text.chars().count() <= LIMIT {
        return text.to_owned();
    }
    text.chars().take(LIMIT).collect::<String>() + "…"
}

#[cfg(test)]
mod tests;
