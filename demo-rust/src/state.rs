use std::sync::Arc;

use sea_orm::DatabaseConnection;

use crate::repository::{SeaCategoryRepository, SeaContentRepository};
use crate::service::{CategoryService, ContentService};

#[derive(Clone)]
pub struct AppState {
    pub categories: Arc<CategoryService>,
    pub contents: Arc<ContentService>,
}

impl AppState {
    /// Wires the SeaORM repositories into the services. Shared by `main` and the endpoint tests.
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            categories: Arc::new(CategoryService::new(Arc::new(SeaCategoryRepository::new(db.clone())))),
            contents: Arc::new(ContentService::new(Arc::new(SeaContentRepository::new(db)))),
        }
    }
}
