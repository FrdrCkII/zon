use anyhow::{Result, anyhow};
use tokio::io::{self, AsyncReadExt};
use tokio::process::Command;

pub async fn pipeline(commands: Vec<Vec<String>>, env_path: &str) -> Result<String> {
    let num_cmds = commands.len();

    let mut children = Vec::with_capacity(num_cmds);
    for (i, cmd_args) in commands.into_iter().enumerate() {
        if cmd_args.is_empty() {
            return Err(anyhow!("Command {} is empty", i));
        }

        let program = &cmd_args[0];
        let args = &cmd_args[1..];

        let mut cmd = Command::new(program);
        cmd.env("PATH", env_path);
        cmd.args(args);

        if i != 0 {
            cmd.stdin(std::process::Stdio::piped());
        } else {
            cmd.stdin(std::process::Stdio::null());
        }

        cmd.stdout(std::process::Stdio::piped());
        cmd.stderr(std::process::Stdio::inherit());

        let child = cmd
            .spawn()
            .map_err(|e| anyhow!("Failed to spawn '{}': {}", program, e))?;
        children.push(child);
    }

    let mut stdout_handles = Vec::with_capacity(num_cmds);
    let mut stdin_handles = Vec::with_capacity(num_cmds);
    for child in &mut children {
        stdout_handles.push(child.stdout.take());
        stdin_handles.push(child.stdin.take());
    }

    // 复制 stdout/stdin
    let mut io_tasks = Vec::with_capacity(num_cmds);
    for i in 0..num_cmds - 1 {
        let mut stdout = stdout_handles[i]
            .take()
            .ok_or_else(|| anyhow!("Missing stdout for command {}", i))?;
        let mut stdin = stdin_handles[i + 1]
            .take()
            .ok_or_else(|| anyhow!("Missing stdin for command {}", i + 1))?;

        let handle =
            tokio::spawn(async move { io::copy(&mut stdout, &mut stdin).await.map(|_| ()) });
        io_tasks.push(handle);
    }

    // 收集
    let mut last_stdout = stdout_handles
        .last_mut()
        .and_then(|h| h.take())
        .ok_or_else(|| anyhow!("Missing stdout for the last command"))?;
    let mut output = String::new();
    last_stdout
        .read_to_string(&mut output)
        .await
        .map_err(|e| anyhow!("Failed to read final output: {}", e))?;

    // 进程状态会反馈是否运行成功，所以没必要确认管道是否正确，直接忽略错误信息
    for task in io_tasks {
        let _ = task.await;
    }

    // 等待
    for (i, mut child) in children.into_iter().enumerate() {
        let status = child
            .wait()
            .await
            .map_err(|e| anyhow!("Failed to wait for command {}: {}", i, e))?;
        if !status.success() {
            return Err(anyhow!("Command {i} exited with status: {status}",));
        }
    }

    // trim
    let output = output.trim().to_owned();

    Ok(output)
}
