use anyhow::Result;
use log::{LevelFilter, Log, Metadata, Record};
use std::io::Write;

pub struct Logger;

impl Log for Logger {
    fn enabled(&self, metadata: &Metadata<'_>) -> bool {
        metadata.level() <= log::max_level()
    }

    fn log(&self, record: &Record<'_>) {
        if self.enabled(record.metadata()) {
            eprintln!("{}: {}", record.level(), record.args());
        }
    }

    fn flush(&self) {
        let _ = std::io::stderr().flush();
    }
}

impl Logger {
    /// 初始化全局日志器。
    ///
    /// 默认级别是 `Warn`：工具靠 `warn!` 报告“输入被丢弃”“依赖被截断”这类
    /// 会影响结果的情况，默认藏起来等于没有。
    pub fn init(level: u8) -> Result<()> {
        // 全局 logger 只能设置一次；重复设置只影响日志，不该让命令失败
        if log::set_boxed_logger(Box::new(Self)).is_err() {
            return Ok(());
        }
        log::set_max_level(match level {
            0 => LevelFilter::Warn,
            1 => LevelFilter::Info,
            2 => LevelFilter::Debug,
            _ => LevelFilter::Trace,
        });

        Ok(())
    }
}
