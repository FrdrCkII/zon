pub mod clap;

pub mod lock;
pub mod module;

use crate::clap::Parsed;
use anyhow::Result;

fn main() -> Result<()> {
    let parsed = clap::parse()?;

    match parsed {
        Parsed::Lock(parsed) => lock::main(parsed),
        Parsed::Module(parsed) => module::main(parsed),
    }
}
