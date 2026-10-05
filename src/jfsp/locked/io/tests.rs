//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::inputs::Config;
use crate::jfsp::locked::{Builtin, Tree, version};
use std::collections::HashMap;

fn lock() -> Lock {
    Lock {
        config: Config::default(),
        builtin: Builtin {
            version: version(),
            types_data: HashMap::new(),
            types_bak: HashMap::new(),
        },
        locked: Tree::default(),
    }
}

#[test]
fn write_leaves_no_temp_file_and_round_trips() {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("target")
        .join(format!("fnlock-lock-{}.lock", std::process::id()));

    assert!(
        Lock::read(&path)
            .expect("读取不存在的锁文件应当成功")
            .is_none()
    );

    lock().write(&path).expect("应当可以写入");
    assert!(!temp_path(&path).exists(), "临时文件应当已被改名");

    let read = Lock::read(&path)
        .expect("应当可以读取")
        .expect("应当有内容");
    assert_eq!(read.builtin.version, version());

    let _ = std::fs::remove_file(&path);
}

#[test]
fn temp_path_stays_in_the_same_directory_and_is_process_unique() {
    let path = Path::new("/tmp/a/channels.lock");
    let temp = temp_path(path);

    assert_eq!(temp.parent(), path.parent());
    let name = temp
        .file_name()
        .expect("应当有文件名")
        .to_string_lossy()
        .to_string();
    assert!(
        name.starts_with("channels.lock.") && name.ends_with(".tmp"),
        "{name}"
    );
}
