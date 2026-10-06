//! Request/response DTOs. Requests carry `validator` rules; responses are built with `From`.

use serde::{Deserialize, Serialize};
use validator::Validate;

use crate::domain::{CategoryWithParent, ContentDetail};
use crate::entities::{category, content};

#[derive(Deserialize, Validate)]
pub struct PageQuery {
    #[serde(default = "default_page")]
    #[validate(range(min = 1))]
    pub page: u64,
    #[serde(default = "default_size", alias = "page_size", alias = "pageSize")]
    #[validate(range(min = 1, max = 100))]
    pub size: u64,
}

fn default_page() -> u64 {
    1
}

fn default_size() -> u64 {
    20
}

#[derive(Deserialize, Validate)]
pub struct UpdateContentRequest {
    #[validate(length(min = 1, max = 1000))]
    pub content: String,
}

#[derive(Serialize)]
pub struct CategoryResponse {
    pub id: i32,
    pub parent_id: Option<i32>,
    pub name: String,
    pub parent: Option<Box<CategoryResponse>>,
}

#[derive(Serialize)]
pub struct ContentResponse {
    pub id: i32,
    pub category_id: Option<i32>,
    pub content: String,
    pub category: Option<CategoryResponse>,
}

#[derive(Serialize)]
pub struct ContentPageResponse {
    pub page: u64,
    pub size: u64,
    pub contents: Vec<ContentResponse>,
}

impl From<category::Model> for CategoryResponse {
    fn from(category: category::Model) -> Self {
        Self { id: category.id, parent_id: category.parent_id, name: category.name, parent: None }
    }
}

impl From<CategoryWithParent> for CategoryResponse {
    fn from(value: CategoryWithParent) -> Self {
        Self { parent: value.parent.map(|parent| Box::new((*parent).into())), ..value.category.into() }
    }
}

impl From<content::Model> for ContentResponse {
    fn from(content: content::Model) -> Self {
        Self { id: content.id, category_id: content.category_id, content: content.content, category: None }
    }
}

impl From<ContentDetail> for ContentResponse {
    fn from(value: ContentDetail) -> Self {
        Self { category: value.category.map(Into::into), ..value.content.into() }
    }
}
