pub mod clap;

pub mod build;
pub mod init;
pub mod lock;
pub mod module;

use crate::clap::Parsed;
use anyhow::Result;

fn main() -> Result<()> {
    let parsed = clap::parse()?;

    match parsed {
        Parsed::Init(parsed) => init::main(parsed),
        Parsed::Lock(parsed) => lock::main(parsed),
        Parsed::Build(parsed) => build::main(parsed),
        Parsed::Module(parsed) => module::main(parsed),
    }
}
