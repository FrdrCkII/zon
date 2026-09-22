use anyhow::{Result, anyhow, bail};
use std::time::Duration;
use tokio::io::{self, AsyncReadExt};
use tokio::process::{Child, Command};
use tokio::task::JoinSet;

/// 单个命令的超时。对锁定工具来说，60 秒足够覆盖绝大多数网络操作。
const COMMAND_TIMEOUT: Duration = Duration::from_secs(60);

pub async fn pipeline(commands: Vec<Vec<String>>, env_path: &str) -> Result<String> {
    if commands.is_empty() {
        bail!("The command list can't be empty");
    }
    for (i, cmd_args) in commands.iter().enumerate() {
        if cmd_args.is_empty() {
            bail!("Command {} is empty", i);
        }
    }

    let num_cmds = commands.len();
    let mut children: Vec<Child> = Vec::with_capacity(num_cmds);

    // 1. spawn 所有进程，kill_on_drop 保证任何退出路径都会清理
    for (i, cmd_args) in commands.iter().enumerate() {
        let mut cmd = Command::new(&cmd_args[0]);
        cmd.env("PATH", env_path)
            .args(&cmd_args[1..])
            .kill_on_drop(true)
            .stdin(if i == 0 {
                std::process::Stdio::null()
            } else {
                std::process::Stdio::piped()
            })
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::inherit());

        let child = cmd
            .spawn()
            .map_err(|e| anyhow!("Failed to spawn '{}': {}", cmd_args[0], e))?;
        children.push(child);
    }

    // 2. 取出所有 pipe 句柄
    let mut stdout_pipes: Vec<_> = children.iter_mut().map(|c| c.stdout.take()).collect();
    let mut stdin_pipes: Vec<_> = children.iter_mut().map(|c| c.stdin.take()).collect();

    // 3. 并发启动所有 IO 任务
    let mut io_set: JoinSet<()> = JoinSet::new();

    for i in 0..num_cmds - 1 {
        let mut stdout = stdout_pipes[i]
            .take()
            .ok_or_else(|| anyhow!("Missing stdout for command {}", i))?;
        let mut stdin = stdin_pipes[i + 1]
            .take()
            .ok_or_else(|| anyhow!("Missing stdin for command {}", i + 1))?;

        io_set.spawn(async move {
            // EPIPE 是正常管道行为（下游提前退出），直接忽略。
            let _ = io::copy(&mut stdout, &mut stdin).await;
            // 显式 drop stdin 触发下游 EOF，而不是等到作用域结束。
            drop(stdin);
        });
    }

    // 4. 最后一个 stdout 的读取也 spawn 成 task，不再阻塞主流程
    let mut last_stdout = stdout_pipes
        .last_mut()
        .and_then(|h| h.take())
        .ok_or_else(|| anyhow!("Missing stdout for the last command"))?;

    let output_task = tokio::spawn(async move {
        let mut output = String::new();
        last_stdout
            .read_to_string(&mut output)
            .await
            .map_err(|e| anyhow!("Failed to read final output: {}", e))?;
        Ok::<String, anyhow::Error>(output)
    });

    // 5. 所有子进程的 wait 也并发化，用 JoinSet 管理
    let mut wait_set: JoinSet<(usize, std::io::Result<std::process::ExitStatus>)> = JoinSet::new();
    for (i, mut child) in children.into_iter().enumerate() {
        wait_set.spawn(async move { (i, child.wait().await) });
    }

    // 6. 整体超时包裹，避免网络挂起导致永久等待
    let result = tokio::time::timeout(COMMAND_TIMEOUT, async {
        // 并发等待 output 和所有子进程
        let output = output_task
            .await
            .map_err(|e| anyhow!("Output task panicked: {}", e))?
            .map_err(|e| anyhow!("Output task failed: {}", e))?;

        // 等所有 IO 复制完成（EPIPE 已被忽略）
        while io_set.join_next().await.is_some() {}

        // 收集所有子进程退出状态
        let mut statuses: Vec<Option<std::process::ExitStatus>> = vec![None; num_cmds];
        while let Some(res) = wait_set.join_next().await {
            let (i, status) = res.map_err(|e| anyhow!("Wait task panicked: {}", e))?;
            statuses[i] =
                Some(status.map_err(|e| anyhow!("Failed to wait for command {}: {}", i, e))?);
        }

        Ok::<_, anyhow::Error>((output, statuses))
    })
    .await;

    // 超时或错误：children 已被移入 wait_set，但 kill_on_drop 在原始 Child 上已生效，
    // 实际上它们已被 wait_set 消耗。这里依赖 JoinSet drop 时 abort 任务，
    // 任务被 abort 时 Child drop，触发 kill_on_drop。
    let (output, statuses) = match result {
        Ok(inner) => inner?,
        Err(_) => bail!("Pipeline timed out after {:?}", COMMAND_TIMEOUT),
    };

    // 7. 检查退出状态，区分真实失败和 SIGPIPE
    let mut first_failure: Option<(usize, std::process::ExitStatus)> = None;
    for (i, status) in statuses.into_iter().enumerate() {
        let Some(status) = status else {
            bail!("Command {} never reported status", i);
        };
        if status.success() {
            continue;
        }
        // SIGPIPE 是正常管道行为，不算失败
        if is_sigpipe(&status) {
            continue;
        }
        if first_failure.is_none() {
            first_failure = Some((i, status));
        }
    }

    if let Some((i, status)) = first_failure {
        bail!(
            "Command {} ({}) exited with status: {}",
            i,
            commands[i].join(" "),
            status
        );
    }

    Ok(output.trim().to_owned())
}

#[cfg(unix)]
fn is_sigpipe(status: &std::process::ExitStatus) -> bool {
    use std::os::unix::process::ExitStatusExt;
    status.signal() == Some(libc::SIGPIPE)
}

#[cfg(not(unix))]
fn is_sigpipe(_: &std::process::ExitStatus) -> bool {
    false
}
