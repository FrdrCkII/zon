//! [`super`] 的单元测试。

use super::*;

#[test]
fn json_config_files_are_supported() {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("target")
        .join(format!("fnlock-config-{}.json", std::process::id()));
    std::fs::write(
        &path,
        r#"{
            "inputs": {
                "hjem": { "ftype": "gitArchive", "repo": "https://github.com/feel-co/hjem" }
            },
            "config": { "autoFollow": false }
        }"#,
    )
    .expect("应当可以写入临时文件");

    let file = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("应当可以建立运行时")
        .block_on(load(&path))
        .expect("应当可以读取配置");

    let _ = std::fs::remove_file(&path);

    assert_eq!(file.inputs.len(), 1);
    assert_eq!(file.inputs["hjem"]["ftype"], "gitArchive");
    let config = file.config.expect("应当有 config");
    assert!(!config.auto_follow);
    // 文件没有给出 defaults 时仍然带上内置默认值
    assert_eq!(config.defaults["hashType"], "sha256");
}
