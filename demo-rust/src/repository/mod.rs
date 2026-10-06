//! Persistence layer: SeaORM queries behind async traits, so services can be tested with fakes.

mod category;
mod content;

use std::collections::HashMap;

use async_trait::async_trait;
use sea_orm::DbErr;

use crate::domain::{CategoryWithParent, ContentDetail};
use crate::entities::{category as category_entity, content as content_entity};

pub use category::SeaCategoryRepository;
pub use content::SeaContentRepository;

#[async_trait]
pub trait CategoryRepository: Send + Sync {
    async fn find_all(&self) -> Result<Vec<CategoryWithParent>, DbErr>;
}

#[async_trait]
pub trait ContentRepository: Send + Sync {
    async fn find_page(&self, offset: u64, limit: u64) -> Result<Vec<ContentDetail>, DbErr>;
    async fn find_by_id(&self, id: i32) -> Result<Option<ContentDetail>, DbErr>;
    /// Returns the updated row without its category, or `None` when the id does not exist.
    async fn update_text(&self, id: i32, text: String) -> Result<Option<content_entity::Model>, DbErr>;
}

/// Assembles `category` with its ancestor chain from already-loaded rows. Stops at the root, at an
/// ancestor missing from `known`, or (defensively) once the chain is longer than `known`, so a
/// cyclic parent_id can never loop forever.
fn with_ancestors(
    category: category_entity::Model,
    known: &HashMap<i32, category_entity::Model>,
) -> CategoryWithParent {
    let mut chain = vec![category];
    while let Some(parent_id) = chain.last().and_then(|c| c.parent_id) {
        match known.get(&parent_id) {
            Some(parent) if chain.len() <= known.len() => chain.push(parent.clone()),
            _ => break,
        }
    }
    let mut node: Option<Box<CategoryWithParent>> = None;
    while let Some(category) = chain.pop() {
        node = Some(Box::new(CategoryWithParent { category, parent: node }));
    }
    *node.expect("chain starts non-empty")
}
