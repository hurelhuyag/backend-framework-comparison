use axum::extract::State;
use axum::Json;

use crate::dto::CategoryResponse;
use crate::error::AppError;
use crate::state::AppState;

pub async fn find_all(State(state): State<AppState>) -> Result<Json<Vec<CategoryResponse>>, AppError> {
    let categories = state.categories.find_all().await?;
    Ok(Json(categories.into_iter().map(Into::into).collect()))
}
