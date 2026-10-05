//! 内置类型数据：程序自带的类型模板，优先级最低。

use super::{Action, Resolver, Task, Type};
use std::collections::HashMap;

macro_rules! s {
    ($($value:expr)?) => {{
        $($value.to_owned())*
    }};
}

macro_rules! svec {
    ($($str:expr),* $(,)?) => {
        vec![$(s!($str)),*]
    };
}

macro_rules! hashset {
    ($($v:expr),* $(,)?) => {
        ::std::collections::HashSet::from([$(s!($v)),*])
    };
}

macro_rules! hashmap {
    ($($k:expr => $v:expr),* $(,)?) => {
        ::std::collections::HashMap::from([$((s!($k), $v)),*])
    };
}

/// 程序内置的类型模板，优先级最低。
///
/// 结果中**保留** [`Task::Builtin`] 简写：写进锁文件时它就是一个字符串，
/// 便于配置文件直接调用预制任务；只有运行任务时才会展开。
///
/// 约定：`immut` 是不可变地址；`locked` 任务（`task_hash_unpack`）会一次写出
/// `hash`（哈希）与 `storePath`（解包后的源码目录，依赖读取由此进入）。
/// 具体类型只需算出 `immut`。
pub fn builtin_types() -> HashMap<String, Type> {
    let types = hashmap![
      // 通用类型：输入直接给出 {url}
      "common" => Type {
          packages: hashset![],
          tasks: hashmap![
              "locked" => Task::Builtin(s!("task_hash_unpack")),
              "immut" => Task::String(s!("{url}")),
          ],
      },
      // 可锁定类型：输入给出 {raw}，先解析出不可变地址再计算哈希
      "lockable" => Type {
          packages: hashset![
              "coreutils",
              "curl",
              "gnugrep",
              "gnused",
          ],
          tasks: hashmap![
              "locked" => Task::Builtin(s!("task_hash_unpack")),
              "immut" => Task::Action(Action {
                  resolver: Resolver::Raw,
                  pure: false,
                  commands: vec![
                      svec!["curl", "-sI", "{raw}"],
                      svec!["tr", "-d", "\\r"],
                      svec!["grep", "-i", "^link:.*rel=\"immutable\""],
                      svec!["sed", "-n", "s/.*<\\([^>]*\\)>.*/\\1/p"],
                      svec!["head", "-n1"],
                  ],
              }),
          ],
      },
      // git 仓库的归档包：输入给出 {repo}，可选 {ref}
      "gitArchive" => Type {
          packages: hashset![
              "coreutils",
              "git",
          ],
          tasks: hashmap![
              "locked" => Task::Builtin(s!("task_hash_unpack")),
              "immut" => Task::String(s!("{repo}/archive/{rev}.{tarballType}")),
              "tarballType" => Task::String(s!("tar.gz")),
              "ref" => Task::String(s!("HEAD")),
              // 不用 --refs：它会把 HEAD 这类伪引用一并过滤掉
              "rev" => Task::Action(Action {
                  resolver: Resolver::Raw,
                  pure: false,
                  commands: vec![
                      svec!["git", "ls-remote", "{repo}", "{ref}"],
                      svec!["cut", "-f1"],
                      svec!["head", "-n1"],
                  ],
              }),
          ],
      },
      // forgejo/gitea 的 release 资源
      "forgejoRelease" => Type {
          packages: hashset![
              "coreutils",
              "curl",
              "gnugrep",
              "jq",
          ],
          tasks: hashmap![
              "locked" => Task::Builtin(s!("task_hash_unpack")),
              "release" => Task::String(s!("latest")),
              "immut" => Task::Action(Action {
                  resolver: Resolver::Raw,
                  pure: false,
                  commands: vec![
                      svec![
                          "curl",
                          "-s",
                          "https://{domain}/api/v1/repos/{repo}/releases/{release}",
                      ],
                      svec!["jq", "-r", ".assets[] | .browser_download_url"],
                      svec!["grep", "{filter}"],
                      svec!["head", "-n1"],
                  ],
              }),
          ],
      },
      // 国内 nix-channels 镜像
      "nixpkgsMirror" => Type {
          packages: hashset![
              "coreutils",
              "curl",
              "gnugrep",
              "gnused",
          ],
          tasks: hashmap![
              "locked" => Task::Builtin(s!("task_hash_unpack")),
              "immut" => Task::String(
                  s!("{mirror}/releases/{rev}/nixexprs.tar.{tarballType}"),
              ),
              "tarballType" => Task::String(s!("xz")),
              "rev" => Task::Action(Action {
                  resolver: Resolver::Raw,
                  pure: false,
                  commands: vec![
                      svec!["curl", "-Ls", "{mirror}/releases/"],
                      svec!["grep", "{channel}"],
                      svec![
                          "sed",
                          "-n",
                          "s/.*title=\"\\([^\"]*\\).*date\">\\([^<]*\\).*/\\2 \\1/p",
                      ],
                      svec!["sort", "-r"],
                      svec!["head", "-n1"],
                      svec!["cut", "-d", " ", "-f3"],
                  ],
              }),
          ],
      },
    ];

    types
}

#[cfg(test)]
mod tests;
