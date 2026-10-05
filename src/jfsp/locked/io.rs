//! 锁文件的读写。

use super::Lock;
use anyhow::{Context, Result};
use log::info;
use std::path::{Path, PathBuf};

impl Lock {
    /// 读取锁文件；文件不存在时返回 `Ok(None)`。
    pub fn read(path: &Path) -> Result<Option<Self>> {
        let text = match std::fs::read_to_string(path) {
            Ok(text) => text,
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => {
                return Ok(None);
            },
            Err(err) => {
                return Err(err).with_context(|| {
                    format!("无法读取锁文件：{}", path.display())
                });
            },
        };

        let lock = serde_json::from_str(&text)
            .with_context(|| format!("锁文件格式不正确：{}", path.display()))?;
        Ok(Some(lock))
    }

    /// 写入锁文件。
    ///
    /// 先写同目录下的临时文件再改名：中途失败（崩溃、被杀）不会留下半个
    /// 锁文件，旧锁文件仍然可用。
    pub fn write(&self, path: &Path) -> Result<()> {
        let mut text =
            serde_json::to_string_pretty(self).context("无法序列化锁文件")?;
        text.push('\n');

        let temp = temp_path(path);
        std::fs::write(&temp, text)
            .with_context(|| format!("无法写入锁文件：{}", temp.display()))?;
        std::fs::rename(&temp, path).with_context(|| {
            format!("无法替换锁文件：{} -> {}", temp.display(), path.display())
        })?;

        info!("已写入锁文件 {}", path.display());
        Ok(())
    }
}

/// 锁文件的临时路径：与目标同目录，保证改名是同一文件系统内的原子操作。
///
/// 名字带上进程号：两个 fnlock 进程同时写锁时，不会互相踩对方的临时文件。
fn temp_path(path: &Path) -> PathBuf {
    let mut name = path.as_os_str().to_owned();
    name.push(format!(".{}.tmp", std::process::id()));
    PathBuf::from(name)
}

#[cfg(test)]
mod tests;
