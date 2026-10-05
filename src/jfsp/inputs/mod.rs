//! 配置文件抽象：求值配置文件并解析输入声明。
//!
//! 同时支持 nix（`nix eval`）与 json 文件；只读取 `inputs` 与 `config`，
//! 配置文件里的其他属性（例如消费锁定结果的 `locked`）保持惰性求值。

mod config;
mod decl;
mod load;

pub use self::config::{Config, ConfigFile};
pub use self::decl::{DEFAULT_GROUP, Declaration, declarations, initial_vars};
pub use self::load::load;
