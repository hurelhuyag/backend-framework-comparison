//! The one place errors become HTTP responses. Handlers and services only return `AppError`.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use sea_orm::DbErr;
use serde::Serialize;
use validator::ValidationErrors;

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("content not found")]
    ContentNotFound,
    #[error("bad request: {0}")]
    BadRequest(String),
    #[error("validation failed")]
    Validation(#[from] ValidationErrors),
    #[error("database error: {0}")]
    Db(#[from] DbErr),
    #[error("internal error")]
    Internal,
}

#[derive(Serialize)]
struct ErrorBody {
    error: &'static str,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    details: Vec<FieldError>,
}

#[derive(Serialize)]
struct FieldError {
    field: String,
    rule: String,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error, details) = match &self {
            AppError::ContentNotFound => (StatusCode::NOT_FOUND, "content_not_found", Vec::new()),
            AppError::BadRequest(reason) => {
                tracing::debug!(%reason, "bad request");
                (StatusCode::BAD_REQUEST, "bad_request", Vec::new())
            }
            AppError::Validation(errors) => (StatusCode::BAD_REQUEST, "validation_failed", field_errors(errors)),
            AppError::Db(_) | AppError::Internal => {
                tracing::error!(error = %self, "request failed");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal_error", Vec::new())
            }
        };
        (status, Json(ErrorBody { error, details })).into_response()
    }
}

fn field_errors(errors: &ValidationErrors) -> Vec<FieldError> {
    let mut details: Vec<FieldError> = errors
        .field_errors()
        .into_iter()
        .flat_map(|(field, errs)| {
            errs.iter().map(move |err| FieldError { field: field.to_string(), rule: err.code.to_string() })
        })
        .collect();
    details.sort_by(|a, b| a.field.cmp(&b.field));
    details
}
