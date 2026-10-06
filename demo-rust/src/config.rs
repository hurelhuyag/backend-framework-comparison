use std::env;

use anyhow::Context;

pub struct Config {
    pub database_url: String,
    pub port: u16,
    pub max_connections: u32,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            database_url: env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://demo.sqlite".to_owned()),
            port: parse_or("PORT", 8081)?,
            max_connections: parse_or("DB_MAX_CONNECTIONS", 16)?,
        })
    }
}

fn parse_or<T>(key: &str, default: T) -> anyhow::Result<T>
where
    T: std::str::FromStr,
    T::Err: std::error::Error + Send + Sync + 'static,
{
    match env::var(key) {
        Ok(raw) => raw.parse().with_context(|| format!("invalid {key}: {raw:?}")),
        Err(_) => Ok(default),
    }
}
