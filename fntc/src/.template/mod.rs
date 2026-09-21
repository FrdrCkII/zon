pub mod clap;

use self::clap::Parsed;
use anyhow::Result;

pub fn main(_: Parsed) -> Result<()> {
    Ok(())
}
