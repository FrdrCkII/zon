use anyhow::{Result, bail};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};

pub type InputItem = HashMap<String, InputValue>;
pub type InputMap = HashMap<String, InputItem>;

#[derive(Serialize, Deserialize)]
pub enum InputValue {
    String(String),
    Commands {
        commands: Vec<Vec<String>>,
        packages: Vec<String>,
        update: bool,
    },
}

impl InputValue {
    pub fn serde(json_str: &str) -> Result<InputMap> {
        let map = serde_json::from_str::<InputMap>(json_str)?;
        Ok(map)
    }

    pub fn get_packages(&self) -> &[String] {
        match self {
            Self::String(_) => &[],
            Self::Commands { packages, .. } => &packages,
        }
    }

    pub fn get_deps(&self) -> Vec<String> {
        fn collect_placeholders(s: &str, out: &mut Vec<String>, seen: &mut HashSet<String>) {
            let mut start = None;

            for (idx, ch) in s.char_indices() {
                match ch {
                    '{' => start = Some(idx + 1),
                    '}' => {
                        if let Some(start_idx) = start.take() {
                            let name = s[start_idx..idx].trim();
                            if !name.is_empty() && seen.insert(name.to_string()) {
                                out.push(name.to_string());
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        let mut deps = Vec::new();
        let mut seen = HashSet::new();

        match self {
            Self::String(template) => {
                collect_placeholders(template, &mut deps, &mut seen);
            }
            Self::Commands { commands, .. } => {
                for cmd in commands {
                    for arg in cmd {
                        collect_placeholders(arg, &mut deps, &mut seen);
                    }
                }
            }
        }

        deps
    }

    pub fn substitute_deps(&self, vars: &HashMap<String, String>) -> Self {
        fn substitute_str(s: &str, vars: &HashMap<String, String>) -> String {
            let mut result = String::with_capacity(s.len());
            let mut chars = s.chars().peekable();

            while let Some(ch) = chars.next() {
                if ch == '{' {
                    let mut var = String::new();
                    let mut closed = false;

                    for next in chars.by_ref() {
                        if next == '}' {
                            closed = true;
                            break;
                        }
                        var.push(next);
                    }

                    if closed {
                        let var_trimmed = var.trim();
                        if let Some(value) = vars.get(var_trimmed) {
                            result.push_str(value);
                        } else {
                            result.push('{');
                            result.push_str(&var);
                            result.push('}');
                        }
                    } else {
                        result.push('{');
                        result.push_str(&var);
                    }
                } else {
                    result.push(ch);
                }
            }

            result
        }

        match self {
            Self::String(s) => Self::String(substitute_str(s, vars)),
            Self::Commands {
                commands,
                packages,
                update,
            } => {
                let new_commands = commands
                    .iter()
                    .map(|cmd| cmd.iter().map(|arg| substitute_str(arg, vars)).collect())
                    .collect();

                Self::Commands {
                    commands: new_commands,
                    packages: packages.clone(),
                    update: *update,
                }
            }
        }
    }
}

pub fn get_packages(map: &InputMap) -> Result<Vec<String>> {
    let inputs_lists = map
        .iter()
        .map(|(_, input)| {
            input
                .iter()
                .map(|(_, input)| input.get_packages())
                .collect::<Vec<&[String]>>()
        })
        .collect::<Vec<Vec<&[String]>>>();

    let packages = {
        let mut seen = HashSet::new();
        let mut result = Vec::new();
        for package_lists in inputs_lists.into_iter() {
            for list in package_lists.into_iter() {
                for s in list {
                    if seen.insert(s.as_str()) {
                        result.push(s.to_string());
                    }
                }
            }
        }

        result
    };

    Ok(packages)
}

// Kahn
pub fn resolve_dependency_order(map: &InputItem) -> Result<Vec<Vec<String>>> {
    let all_nodes: HashSet<String> = map.keys().cloned().collect();

    let mut successors: HashMap<String, Vec<String>> = HashMap::new();
    let mut indegree: HashMap<String, usize> = HashMap::new();

    for (name, value) in map {
        indegree.entry(name.clone()).or_insert(0);

        let deps: HashSet<String> = value
            .get_deps()
            .into_iter()
            .filter(|dep| all_nodes.contains(dep) && dep != name)
            .collect();

        *indegree.get_mut(name).unwrap() += deps.len();

        for dep in deps {
            successors.entry(dep).or_default().push(name.clone());
        }
    }

    let mut result: Vec<Vec<String>> = Vec::new();
    let mut queue: VecDeque<String> = indegree
        .iter()
        .filter(|(_, deg)| **deg == 0)
        .map(|(node, _)| node.clone())
        .collect();

    let mut sorted_queue: Vec<String> = queue.into_iter().collect();
    sorted_queue.sort();
    queue = sorted_queue.into();

    let mut processed = 0;

    while !queue.is_empty() {
        let mut layer = Vec::new();
        let mut next_queue = VecDeque::new();

        while let Some(node) = queue.pop_front() {
            layer.push(node.clone());
            processed += 1;

            if let Some(succs) = successors.get(&node) {
                for succ in succs {
                    let deg = indegree.get_mut(succ).unwrap();
                    *deg -= 1;
                    if *deg == 0 {
                        next_queue.push_back(succ.clone());
                    }
                }
            }
        }

        layer.sort();
        result.push(layer);

        let mut sorted_next: Vec<String> = next_queue.into_iter().collect();
        sorted_next.sort();
        queue = sorted_next.into();
    }

    if processed != map.len() {
        bail!("There’s a loop or missing node in the dependency")
    }

    Ok(result)
}
