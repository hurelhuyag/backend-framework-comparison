use std::any::Any;

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use axum::Router;
use tower_http::catch_panic::CatchPanicLayer;
use tower_http::trace::TraceLayer;

use crate::error::AppError;
use crate::handlers::{category, content};
use crate::state::AppState;

pub fn router(state: AppState) -> Router {
    // Mounted at both /... and /api/... so either benchmark URL shape works.
    let api = Router::new()
        .route("/contents", get(content::find_page))
        .route("/contents/{id}", get(content::find_by_id).put(content::update_text))
        .route("/categories", get(category::find_all));

    Router::new()
        .route("/healthz", get(|| async { StatusCode::NO_CONTENT }))
        .merge(api.clone())
        .nest("/api", api)
        // Cross-cutting layers; the last one added runs outermost.
        // TraceLayer emits a span and a response event per request at DEBUG.
        .layer(TraceLayer::new_for_http())
        .layer(CatchPanicLayer::custom(on_panic))
        .with_state(state)
}

fn on_panic(panic: Box<dyn Any + Send + 'static>) -> Response {
    let message = panic
        .downcast_ref::<String>()
        .map(String::as_str)
        .or_else(|| panic.downcast_ref::<&str>().copied())
        .unwrap_or("unknown panic");
    tracing::error!(panic = message, "panic recovered");
    AppError::Internal.into_response()
}
