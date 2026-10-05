use super::*;

fn hash_resolver() -> Resolver {
    Resolver::Json(HashMap::from([
        ("hash".to_owned(), "locked".to_owned()),
        ("storePath".to_owned(), "storePath".to_owned()),
    ]))
}

fn parse(json: &str) -> Task {
    serde_json::from_str(json).expect("应当可以解析")
}

#[test]
fn actions_round_trip_through_json() {
    let actions = [
        Action {
            resolver: Resolver::Raw,
            pure: false,
            commands: vec![vec!["true".to_owned()]],
        },
        Action {
            resolver: hash_resolver(),
            pure: true,
            commands: vec![
                vec!["git".to_owned(), "ls-remote".to_owned()],
                vec!["cut".to_owned(), "-f1".to_owned()],
            ],
        },
    ];

    for action in actions {
        let text = serde_json::to_string(&action).expect("应当可以序列化");
        assert_eq!(
            serde_json::from_str::<Action>(&text).expect("应当可以解析"),
            action,
            "往返失败：{text}"
        );
    }
}

#[test]
fn raw_resolver_is_omitted() {
    let action = Action {
        resolver: Resolver::Raw,
        pure: false,
        commands: vec![vec!["true".to_owned()]],
    };
    let text = serde_json::to_string(&action).expect("应当可以序列化");
    assert!(!text.contains("resolver"), "不应写出 resolver：{text}");
    assert!(!text.contains("pure"), "不应写出 pure=false：{text}");
    assert_eq!(
        serde_json::from_str::<Action>(&text).expect("应当可以解析"),
        action
    );
}

#[test]
fn json_resolver_extracts_named_properties() {
    let output = r#"{"hash":"sha256-abc","storePath":"/nix/store/x"}"#;
    let mut produced = hash_resolver()
        .extract("locked", output)
        .expect("应当可以解析");
    produced.sort();

    assert_eq!(
        produced,
        vec![
            ("locked".to_owned(), "sha256-abc".to_owned()),
            ("storePath".to_owned(), "/nix/store/x".to_owned()),
        ]
    );

    // 键名与属性名可以自定义
    assert_eq!(hash_resolver().properties("locked").len(), 2);
    assert_eq!(Resolver::Raw.properties("rev"), vec!["rev"]);
}

#[test]
fn json_resolver_skips_missing_keys() {
    let produced = hash_resolver()
        .extract("locked", r#"{"hash":"sha256-abc"}"#)
        .expect("应当可以解析");
    assert_eq!(
        produced,
        vec![("locked".to_owned(), "sha256-abc".to_owned())]
    );

    assert!(hash_resolver().extract("locked", "not json").is_err());
    assert!(hash_resolver().extract("locked", "[1,2]").is_err());
}

#[test]
fn builtin_shorthand_round_trips_as_a_string() {
    let task = Task::Builtin("task_hash_unpack".to_owned());
    let text = serde_json::to_string(&task).expect("应当可以序列化");
    assert_eq!(text, "\"task_hash_unpack\"");
    assert_eq!(parse(&text), task);
}

#[test]
fn unknown_builtin_like_string_is_rejected() {
    assert!(serde_json::from_str::<Task>("\"task_missing\"").is_err());
    // 普通模板仍然是字符串
    assert_eq!(parse("\"{url}\""), Task::String("{url}".to_owned()));
}
