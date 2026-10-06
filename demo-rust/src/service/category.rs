use std::sync::Arc;

use crate::domain::CategoryWithParent;
use crate::error::AppError;
use crate::repository::CategoryRepository;

pub struct CategoryService {
    categories: Arc<dyn CategoryRepository>,
}

impl CategoryService {
    pub fn new(categories: Arc<dyn CategoryRepository>) -> Self {
        Self { categories }
    }

    pub async fn find_all(&self) -> Result<Vec<CategoryWithParent>, AppError> {
        Ok(self.categories.find_all().await?)
    }
}
