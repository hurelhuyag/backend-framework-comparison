//! Composition root: loads config, builds every layer by hand and serves until SIGINT/SIGTERM.

// The 100-category literal in src/tests.rs is deeper than json!'s default macro recursion limit.
#![cfg_attr(test, recursion_limit = "1024")]

mod config;
mod domain;
mod dto;
mod entities;
mod error;
mod extract;
mod handlers;
mod repository;
mod routes;
mod service;
mod state;
#[cfg(test)]
mod tests;

use sea_orm::{ConnectOptions, Database};
use tokio::net::TcpListener;
use tracing_subscriber::EnvFilter;

use crate::config::Config;
use crate::state::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // RUST_LOG overrides; WARN by default like the other demos, so per-request spans are off.
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("warn")))
        .init();

    let config = Config::from_env()?;

    let mut options = ConnectOptions::new(&config.database_url);
    // SeaORM logs every statement at INFO by default; the other demos only log WARN and up.
    options.max_connections(config.max_connections).sqlx_logging(false);
    let db = Database::connect(options).await?;

    let state = AppState::new(db.clone());

    let listener = TcpListener::bind(("0.0.0.0", config.port)).await?;
    tracing::warn!(port = config.port, "server started");
    axum::serve(listener, routes::router(state))
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    db.close().await?;
    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };
    let terminate = async {
        if let Ok(mut signal) = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()) {
            signal.recv().await;
        }
    };
    tokio::select! {
        () = ctrl_c => {},
        () = terminate => {},
    }
}
