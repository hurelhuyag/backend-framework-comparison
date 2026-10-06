//! Aggregates the repositories assemble from SeaORM rows and the services hand to handlers.

use crate::entities::{category, content};

/// A category with its whole ancestor chain: `parent`, then `parent.parent`, up to the root.
pub struct CategoryWithParent {
    pub category: category::Model,
    pub parent: Option<Box<CategoryWithParent>>,
}

pub struct ContentDetail {
    pub content: content::Model,
    pub category: Option<CategoryWithParent>,
}
