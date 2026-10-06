use std::sync::Arc;

use crate::domain::ContentDetail;
use crate::entities::content;
use crate::error::AppError;
use crate::repository::ContentRepository;

pub struct ContentService {
    contents: Arc<dyn ContentRepository>,
}

impl ContentService {
    pub fn new(contents: Arc<dyn ContentRepository>) -> Self {
        Self { contents }
    }

    /// `page` is 1-based; page and size are already validated by the handler.
    pub async fn find_page(&self, page: u64, size: u64) -> Result<Vec<ContentDetail>, AppError> {
        Ok(self.contents.find_page((page - 1) * size, size).await?)
    }

    pub async fn find_by_id(&self, id: i32) -> Result<ContentDetail, AppError> {
        self.contents.find_by_id(id).await?.ok_or(AppError::ContentNotFound)
    }

    /// Rewrites only the text, so the row count never changes and reads stay comparable.
    pub async fn update_text(&self, id: i32, text: String) -> Result<content::Model, AppError> {
        self.contents.update_text(id, text).await?.ok_or(AppError::ContentNotFound)
    }
}
