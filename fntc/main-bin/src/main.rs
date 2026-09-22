use anyhow::{Result, anyhow};

fn main() -> Result<()> {
  let args: Vec<String> = std::env::args().collect::<Vec<String>>();

  match args[1].as_str() {
    "lock" => fntc_lock::run(args.to_owned()),
    "module" => fntc_module::run(args.to_owned()),

    _ => Err(anyhow!("Unknown Command")),
  }
}
