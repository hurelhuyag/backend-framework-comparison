use axum::extract::State;
use axum::Json;

use crate::dto::{ContentPageResponse, ContentResponse, PageQuery, UpdateContentRequest};
use crate::error::AppError;
use crate::extract::{IdPath, ValidatedJson, ValidatedQuery};
use crate::state::AppState;

pub async fn find_page(
    State(state): State<AppState>,
    ValidatedQuery(query): ValidatedQuery<PageQuery>,
) -> Result<Json<ContentPageResponse>, AppError> {
    let contents = state.contents.find_page(query.page, query.size).await?;
    Ok(Json(ContentPageResponse {
        page: query.page,
        size: query.size,
        contents: contents.into_iter().map(Into::into).collect(),
    }))
}

pub async fn find_by_id(State(state): State<AppState>, IdPath(id): IdPath) -> Result<Json<ContentResponse>, AppError> {
    Ok(Json(state.contents.find_by_id(id).await?.into()))
}

pub async fn update_text(
    State(state): State<AppState>,
    IdPath(id): IdPath,
    ValidatedJson(body): ValidatedJson<UpdateContentRequest>,
) -> Result<Json<ContentResponse>, AppError> {
    Ok(Json(state.contents.update_text(id, body.content).await?.into()))
}
