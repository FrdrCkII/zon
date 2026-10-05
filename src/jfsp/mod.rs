pub mod deps;
pub mod inputs;
pub mod locked;
pub(crate) mod nix;
pub mod types;

use serde::{Serialize, Serializer};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};

/// 序列化 `HashSet<String>`：按键名排序，避免锁文件随哈希顺序抖动。
pub(crate) fn serialize_sorted_set<S>(
    set: &HashSet<String>,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let sorted: BTreeSet<_> = set.iter().collect();
    sorted.serialize(serializer)
}

/// 序列化 `HashMap`：按键名排序，避免锁文件随哈希顺序抖动。
pub(crate) fn serialize_sorted_map<S, V>(
    map: &HashMap<String, V>,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
    V: Serialize,
{
    let sorted: BTreeMap<_, _> = map.iter().collect();
    sorted.serialize(serializer)
}
