use std::collections::HashMap;

use async_trait::async_trait;
use sea_orm::{DatabaseConnection, DbErr, EntityTrait, QueryOrder};

use super::{with_ancestors, CategoryRepository};
use crate::domain::CategoryWithParent;
use crate::entities::category;

pub struct SeaCategoryRepository {
    db: DatabaseConnection,
}

impl SeaCategoryRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }
}

#[async_trait]
impl CategoryRepository for SeaCategoryRepository {
    async fn find_all(&self) -> Result<Vec<CategoryWithParent>, DbErr> {
        let categories = category::Entity::find().order_by_asc(category::Column::Id).all(&self.db).await?;

        // Every ancestor is already in this result set, so the whole chain needs no extra query.
        let by_id: HashMap<i32, category::Model> =
            categories.iter().map(|category| (category.id, category.clone())).collect();

        Ok(categories.into_iter().map(|category| with_ancestors(category, &by_id)).collect())
    }
}
