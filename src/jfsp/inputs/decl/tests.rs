//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::types::builtin_types;

/// 构造输入声明：`(名称, [(键, 值)])`。
fn inputs(
    pairs: Vec<(&str, Vec<(&str, Value)>)>,
) -> HashMap<String, HashMap<String, Value>> {
    pairs
        .into_iter()
        .map(|(name, attrs)| {
            let attrs = attrs
                .into_iter()
                .map(|(key, value)| (key.to_owned(), value))
                .collect();
            (name.to_owned(), attrs)
        })
        .collect()
}

fn vars(pairs: &[(&str, &str)]) -> HashMap<String, String> {
    pairs
        .iter()
        .map(|(k, v)| ((*k).to_owned(), (*v).to_owned()))
        .collect()
}

#[test]
fn declarations_are_sorted_and_typed() {
    let decls = declarations(
        inputs(vec![
            ("b", vec![("ftype", Value::String("common".to_owned()))]),
            (
                "a",
                vec![
                    ("ftype", Value::String("common".to_owned())),
                    ("url", Value::String("https://example.com".to_owned())),
                    ("group", Value::String("foo".to_owned())),
                ],
            ),
        ]),
        &builtin_types(),
    )
    .expect("应当可以解析");

    assert_eq!(decls.len(), 2);
    assert_eq!(decls[0].name, "a");
    assert_eq!(decls[0].ftype, "common");
    assert_eq!(decls[0].group, "foo");
    assert_eq!(decls[0].params["url"], "https://example.com");
    // 未声明 group 时回落到默认分组
    assert_eq!(decls[1].name, "b");
    assert_eq!(decls[1].group, DEFAULT_GROUP);
}

#[test]
fn declarations_reject_missing_or_unknown_type() {
    let unknown = inputs(vec![(
        "a",
        vec![("ftype", Value::String("missing".to_owned()))],
    )]);
    assert!(declarations(unknown, &builtin_types()).is_err());

    let missing = inputs(vec![("a", vec![])]);
    assert!(declarations(missing, &builtin_types()).is_err());
}

#[test]
fn config_defaults_are_the_fallback_layer() {
    let config = Config {
        defaults: vars(&[("hashType", "sha512"), ("ref", "HEAD")]),
        ..Config::default()
    };
    let params = vars(&[("ref", "refs/heads/main")]);

    let vars = initial_vars(&params, &config);
    // 未声明的值回退到 defaults
    assert_eq!(vars["hashType"], "sha512");
    // 显式声明的参数优先于 defaults
    assert_eq!(vars["ref"], "refs/heads/main");
    assert!(!vars.contains_key("missing"));
}
