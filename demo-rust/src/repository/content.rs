use std::collections::HashMap;

use async_trait::async_trait;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, DatabaseConnection, DbErr, EntityTrait, IntoActiveModel, QueryFilter, QueryOrder,
    QuerySelect, Set,
};

use super::{with_ancestors, ContentRepository};
use crate::domain::ContentDetail;
use crate::entities::{category, content};

pub struct SeaContentRepository {
    db: DatabaseConnection,
}

impl SeaContentRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Eager-loads the ancestor chain of every category in `rows`: `category.parent` is a
    /// self-referencing FK, which SeaORM's typed `and_also_related` cannot alias, so each level up
    /// is one batched `IN (...)` query until no unknown parent ids remain (two extra queries at
    /// most for the 3-level tree). The same shape Prisma and Django produce for nested relations.
    async fn attach_ancestors(
        &self,
        rows: Vec<(content::Model, Option<category::Model>)>,
    ) -> Result<Vec<ContentDetail>, DbErr> {
        let mut known: HashMap<i32, category::Model> =
            rows.iter().filter_map(|(_, category)| category.clone()).map(|c| (c.id, c)).collect();

        let mut pending = missing_parents(known.values(), &known);
        while !pending.is_empty() {
            let parents = category::Entity::find().filter(category::Column::Id.is_in(pending)).all(&self.db).await?;
            known.extend(parents.iter().map(|parent| (parent.id, parent.clone())));
            pending = missing_parents(parents.iter(), &known);
        }

        Ok(rows
            .into_iter()
            .map(|(content, category)| ContentDetail {
                content,
                category: category.map(|category| with_ancestors(category, &known)),
            })
            .collect())
    }
}

/// Parent ids referenced by `categories` that are not loaded yet, sorted and deduplicated.
fn missing_parents<'a>(
    categories: impl Iterator<Item = &'a category::Model>,
    known: &HashMap<i32, category::Model>,
) -> Vec<i32> {
    let mut ids: Vec<i32> =
        categories.filter_map(|category| category.parent_id).filter(|id| !known.contains_key(id)).collect();
    ids.sort_unstable();
    ids.dedup();
    ids
}

#[async_trait]
impl ContentRepository for SeaContentRepository {
    async fn find_page(&self, offset: u64, limit: u64) -> Result<Vec<ContentDetail>, DbErr> {
        let rows = content::Entity::find()
            .find_also_related(category::Entity)
            .order_by_asc(content::Column::Id)
            .offset(offset)
            .limit(limit)
            .all(&self.db)
            .await?;
        self.attach_ancestors(rows).await
    }

    async fn find_by_id(&self, id: i32) -> Result<Option<ContentDetail>, DbErr> {
        let Some(row) = content::Entity::find_by_id(id).find_also_related(category::Entity).one(&self.db).await? else {
            return Ok(None);
        };
        Ok(self.attach_ancestors(vec![row]).await?.pop())
    }

    async fn update_text(&self, id: i32, text: String) -> Result<Option<content::Model>, DbErr> {
        let Some(content) = content::Entity::find_by_id(id).one(&self.db).await? else {
            return Ok(None);
        };
        let mut active = content.into_active_model();
        active.content = Set(text);
        Ok(Some(active.update(&self.db).await?))
    }
}
