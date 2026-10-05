use clap::{Parser, ValueEnum};
use std::path::PathBuf;

#[derive(Parser)]
pub struct Args {
    /// 配置文件路径
    #[arg(short, long, default_value = "channels.nix")]
    pub config: PathBuf,

    /// 要执行的动作
    #[arg(short, long, value_enum, default_value_t = Update::Lock)]
    pub action: Update,

    /// 以 ',' 分隔的名单，含义取决于 --action：update 为输入名、update-group 为分组名，留空表示全部
    #[arg(short, long, default_value = "")]
    pub list: String,

    /// 提高日志可见度，可重复
    #[arg(short, long, action = clap::ArgAction::Count)]
    pub verbose: u8,
}

/// 更新策略：决定哪些输入的属性需要重新计算。
#[derive(Clone, ValueEnum)]
pub enum Update {
    /// 只补齐缺失的属性，尽量复用锁文件里的值
    Lock,

    /// 更新 --list 指名的输入；名单为空时更新全部输入
    Update,

    /// 更新默认分组（default）的输入
    UpdateDefault,

    /// 更新 --list 指名的分组里的输入；名单为空时更新全部分组
    UpdateGroup,

    /// 更新全部输入
    UpdateAll,
}
