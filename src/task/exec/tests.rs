//! [`super`] 的单元测试。

use super::*;

#[test]
fn path_with_prepends_env_bin() {
    assert_eq!(path_with(None), None);

    let path = path_with(Some("/nix/store/abc-fnlock-pkgs")).expect("应当有值");
    assert!(path.starts_with("/nix/store/abc-fnlock-pkgs/bin"));
}

#[test]
fn pipeline_connects_standard_output_to_standard_input() {
    let runtime = runtime();
    let stages = vec![
        vec!["printf".to_owned(), "hello".to_owned()],
        vec!["tr".to_owned(), "a-z".to_owned(), "A-Z".to_owned()],
    ];
    let output = runtime
        .block_on(pipeline(&stages, None))
        .expect("应当可以执行");
    assert_eq!(output, "HELLO");
}

#[test]
fn pipeline_reports_failure() {
    let runtime = runtime();
    let stages = vec![vec!["false".to_owned()]];
    assert!(runtime.block_on(pipeline(&stages, None)).is_err());
}

#[test]
fn pipeline_tolerates_upstream_stopping_early() {
    let runtime = runtime();
    // head 读够一行就退出，上游 cut 随即拿到 EPIPE 而非零退出；
    // 这属于管道正常结束，不应该判定失败
    let stages = vec![
        vec!["seq".to_owned(), "1".to_owned(), "200000".to_owned()],
        vec!["cut".to_owned(), "-f1".to_owned()],
        vec!["head".to_owned(), "-n1".to_owned()],
    ];
    let output = runtime
        .block_on(pipeline(&stages, None))
        .expect("应当可以执行");
    assert_eq!(output, "1");
}

#[test]
fn pipeline_reports_upstream_failure_when_output_is_empty() {
    let runtime = runtime();
    // 上游真的失败且管道没有输出时仍然要报错
    let stages = vec![
        vec!["false".to_owned()],
        vec!["head".to_owned(), "-n1".to_owned()],
    ];
    assert!(runtime.block_on(pipeline(&stages, None)).is_err());
}

/// tokio 没有开 `macros` feature，测试里手动建一个运行时。
fn runtime() -> tokio::runtime::Runtime {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("应当可以建立运行时")
}
