mod entities;

use std::collections::HashMap;
use std::env;

use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use axum::{Json, Router};
use sea_orm::{
    ColumnTrait, ConnectOptions, Database, DatabaseConnection, DbErr, EntityTrait, QueryFilter, QueryOrder,
    QuerySelect,
};
use serde::{Deserialize, Serialize};

use entities::{category, content};

#[derive(Clone)]
struct AppState {
    db: DatabaseConnection,
}

#[derive(Deserialize)]
struct Pagination {
    page: Option<u64>,
    #[serde(alias = "page_size", alias = "pageSize")]
    size: Option<u64>,
}

impl Pagination {
    /// Same defaults as the Django/NextJS demos: page 1, 20 rows, hard cap of 100.
    fn resolve(&self) -> (u64, u64) {
        let page = self.page.filter(|page| *page > 0).unwrap_or(1);
        let size = self.size.filter(|size| *size > 0).unwrap_or(20).min(100);
        (page, size)
    }
}

#[derive(Serialize)]
struct CategoryView {
    id: i32,
    parent_id: Option<i32>,
    name: String,
    parent: Option<Box<CategoryView>>,
}

#[derive(Serialize)]
struct ContentView {
    id: i32,
    category_id: Option<i32>,
    content: String,
    category: Option<CategoryView>,
}

#[derive(Serialize)]
struct ContentsResponse {
    page: u64,
    size: u64,
    contents: Vec<ContentView>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://demo.sqlite".to_owned());
    let mut options = ConnectOptions::new(url);
    options.max_connections(16).sqlx_logging(false);
    let db = Database::connect(options).await?;

    // Mounted twice so both `ab` command shapes in the repo README work: /contents and /api/contents.
    let routes = Router::new()
        .route("/contents", get(get_contents))
        .route("/contents/{id}", get(get_content))
        .route("/categories", get(get_categories));
    let app = Router::new()
        .merge(routes.clone())
        .nest("/api", routes)
        .with_state(AppState { db });

    let port = env::var("PORT").unwrap_or_else(|_| "8081".to_owned());
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}")).await?;
    println!("Server started at :{port}");
    axum::serve(listener, app).await?;
    Ok(())
}

async fn get_contents(
    State(state): State<AppState>,
    Query(pagination): Query<Pagination>,
) -> Result<Json<ContentsResponse>, AppError> {
    let (page, size) = pagination.resolve();

    let rows: Vec<(content::Model, Option<category::Model>)> = content::Entity::find()
        .find_also_related(category::Entity)
        .order_by_asc(content::Column::Id)
        .offset((page - 1) * size)
        .limit(size)
        .all(&state.db)
        .await?;

    let parents = load_parents(&state.db, rows.iter().filter_map(|(_, category)| category.as_ref())).await?;

    Ok(Json(ContentsResponse {
        page,
        size,
        contents: rows
            .into_iter()
            .map(|(content, category)| ContentView {
                id: content.id,
                category_id: content.category_id,
                content: content.content,
                category: category.map(|category| CategoryView {
                    id: category.id,
                    parent_id: category.parent_id,
                    name: category.name,
                    parent: category.parent_id.and_then(|id| parents.get(&id)).map(|parent| {
                        Box::new(CategoryView {
                            id: parent.id,
                            parent_id: parent.parent_id,
                            name: parent.name.clone(),
                            parent: None,
                        })
                    }),
                }),
            })
            .collect(),
    }))
}

async fn get_content(State(state): State<AppState>, Path(id): Path<i32>) -> Result<Json<ContentView>, AppError> {
    let (content, category) = content::Entity::find_by_id(id)
        .find_also_related(category::Entity)
        .one(&state.db)
        .await?
        .ok_or(AppError::NotFound)?;

    let parents = load_parents(&state.db, category.iter()).await?;

    Ok(Json(ContentView {
        id: content.id,
        category_id: content.category_id,
        content: content.content,
        category: category.map(|category| CategoryView {
            id: category.id,
            parent_id: category.parent_id,
            name: category.name,
            parent: category.parent_id.and_then(|id| parents.get(&id)).map(|parent| {
                Box::new(CategoryView {
                    id: parent.id,
                    parent_id: parent.parent_id,
                    name: parent.name.clone(),
                    parent: None,
                })
            }),
        }),
    }))
}

async fn get_categories(State(state): State<AppState>) -> Result<Json<Vec<CategoryView>>, AppError> {
    let categories = category::Entity::find()
        .order_by_asc(category::Column::Id)
        .all(&state.db)
        .await?;

    // Every parent is already in this result set, so no second query is needed here.
    let by_id: HashMap<i32, category::Model> = categories
        .iter()
        .cloned()
        .map(|category| (category.id, category))
        .collect();

    Ok(Json(
        categories
            .into_iter()
            .map(|category| CategoryView {
                id: category.id,
                parent_id: category.parent_id,
                name: category.name,
                parent: category.parent_id.and_then(|id| by_id.get(&id)).map(|parent| {
                    Box::new(CategoryView {
                        id: parent.id,
                        parent_id: parent.parent_id,
                        name: parent.name.clone(),
                        parent: None,
                    })
                }),
            })
            .collect(),
    ))
}

/// Second hop of the eager load: `category.parent` is a self-referencing FK, which SeaORM's
/// typed `and_also_related` cannot alias, so the parents are fetched in one batched `IN (...)`
/// query. This is the same shape Prisma and Django produce for a nested relation.
async fn load_parents<'a, I>(db: &DatabaseConnection, categories: I) -> Result<HashMap<i32, category::Model>, DbErr>
where
    I: Iterator<Item = &'a category::Model>,
{
    let mut ids: Vec<i32> = categories.filter_map(|category| category.parent_id).collect();
    ids.sort_unstable();
    ids.dedup();
    if ids.is_empty() {
        return Ok(HashMap::new());
    }

    Ok(category::Entity::find()
        .filter(category::Column::Id.is_in(ids))
        .all(db)
        .await?
        .into_iter()
        .map(|parent| (parent.id, parent))
        .collect())
}

enum AppError {
    NotFound,
    Db(DbErr),
}

impl From<DbErr> for AppError {
    fn from(err: DbErr) -> Self {
        AppError::Db(err)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        match self {
            AppError::NotFound => (StatusCode::NOT_FOUND, "content not found").into_response(),
            AppError::Db(err) => {
                eprintln!("db error: {err}");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal error").into_response()
            }
        }
    }
}
