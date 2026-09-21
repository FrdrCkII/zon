use anyhow::Result;

pub struct Parsed {}

pub const HELP: &str = r#"
Options:
"#;

pub fn parse(_: Vec<String>) -> Result<Parsed> {
    Ok(Parsed {})
}
