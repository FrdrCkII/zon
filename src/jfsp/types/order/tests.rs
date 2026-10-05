//! [`super`] 的单元测试。

use super::*;
use crate::jfsp::types::{Action, Resolver};

fn string_task(template: &str) -> Task {
    Task::String(template.to_owned())
}

fn command_task(argv: &[&str]) -> Task {
    Task::Action(Action {
        resolver: Resolver::Raw,
        pure: false,
        commands: vec![argv.iter().map(|arg| (*arg).to_owned()).collect()],
    })
}

#[test]
fn resolve_order_layers_by_dependency() {
    let tasks: HashMap<String, Task> = [
        ("ref", string_task("{ref}")),
        (
            "rev",
            command_task(&["git", "ls-remote", "{repo}", "{ref}"]),
        ),
        ("url", string_task("{repo}/archive/{rev}.tar.gz")),
        ("hash", command_task(&["nix", "{url}"])),
    ]
    .into_iter()
    .map(|(k, v)| (k.to_owned(), v))
    .collect();

    let layers = resolve_order(&tasks).expect("应当可以排序");
    let position = |name: &str| {
        layers
            .iter()
            .position(|layer| layer.contains(&name.to_owned()))
            .expect("属性应当存在")
    };
    assert!(position("ref") < position("rev"));
    assert!(position("rev") < position("url"));
    assert!(position("url") < position("hash"));
}

#[test]
fn resolve_order_rejects_cycle() {
    let tasks: HashMap<String, Task> =
        [("a", string_task("{b}")), ("b", string_task("{a}"))]
            .into_iter()
            .map(|(k, v)| (k.to_owned(), v))
            .collect();
    assert!(resolve_order(&tasks).is_err());
}
