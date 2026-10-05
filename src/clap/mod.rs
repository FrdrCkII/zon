mod cli;
mod log;

pub use self::cli::Update;

use self::cli::Args;
use anyhow::Result;
use clap::Parser;
use std::collections::HashSet;
use std::path::PathBuf;

/// 解析后的命令行参数。
///
/// 简单逻辑（路径推导、名单拆分）在这里完成，复杂逻辑交给 `task` 模块。
pub struct Parsed {
    /// 配置文件路径
    pub config: PathBuf,
    /// 锁文件路径：与配置文件同名的 `.lock` 文件
    pub locked: PathBuf,
    /// 更新策略
    pub update: Update,
    /// 与 `update` 配合的名单
    pub list: HashSet<String>,
}

impl Parsed {
    pub fn parse() -> Result<Self> {
        let args = Args::parse();
        log::Logger::init(args.verbose)?;

        let config = args.config;
        let locked = config.with_extension("lock");
        // 路径拼不出锁文件时早点说清楚，别等到写文件才失败
        if locked == config || locked.file_name().is_none() {
            anyhow::bail!(
                "无法从配置文件路径推导出锁文件路径：{}",
                config.display()
            );
        }

        Ok(Self {
            locked,
            list: args
                .list
                .split(',')
                .map(str::trim)
                .filter(|name| !name.is_empty())
                .map(str::to_owned)
                .collect(),
            config,
            update: args.action,
        })
    }
}
