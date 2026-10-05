pub mod clap;
pub mod jfsp;
pub mod task;

use anyhow::Result;

fn main() -> Result<()> {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?
        .block_on(async_main())
}

async fn async_main() -> Result<()> {
    let parsed = clap::Parsed::parse()?;
    task::lock(&parsed).await
}
