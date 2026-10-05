//! 锁文件抽象：结构定义、读写与类型数据解析。

mod io;
mod resolve;
mod tree;

pub use self::resolve::{Types, resolve_types};
pub use self::tree::{
    Builtin, ItemDep, ItemTop, Lock, Tree, VER_FILE, VER_LOCK, VER_TYPE,
    version,
};
