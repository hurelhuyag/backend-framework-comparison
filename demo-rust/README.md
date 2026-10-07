# demo-rust — Rust / Axum / SeaORM / PostgreSQL

Sixth-language entry in the comparison: **Axum 0.8** (most-downloaded Rust web framework) +
**SeaORM 2.0** (the popular async Rust ORM) against the same PostgreSQL dataset (`db/generate.sql`) as every other demo.

SeaORM is used deliberately instead of raw `sqlx`. Every other demo in this repo goes through an ORM
(GORM, Hibernate, Prisma, Eloquent, Django ORM), so hand-written SQL here would measure a different
workload and flatter Rust for the wrong reason.

## Layout

Structured the way a production Axum service usually is:

```
src/main.rs        composition root: tracing, config, wiring, graceful shutdown
src/config.rs      env config
src/routes.rs      router + tower-http layers (TraceLayer, CatchPanicLayer)
src/handlers/      thin HTTP handlers: extract, call a service, map to a DTO
src/extract.rs     ValidatedJson / ValidatedQuery / IdPath extractors with JSON rejections
src/dto.rs         request DTOs (validator rules) and response DTOs (From impls)
src/error.rs       AppError (thiserror) -> the single IntoResponse error mapping
src/service/       business layer, depends on repository traits only
src/repository/    async-trait repositories, SeaORM implementations
src/domain.rs      aggregates assembled by repositories
src/entities/      SeaORM entities
```

| Concern            | Crate                                        |
|--------------------|----------------------------------------------|
| HTTP               | axum 0.8, tower-http                         |
| Validation         | validator                                    |
| ORM                | sea-orm 2.0 (sqlx-postgres)                  |
| Logging / tracing  | tracing, tracing-subscriber (JSON, EnvFilter)|
| Errors             | thiserror (app), anyhow (main)               |
| DI / mapping       | constructor injection via `Arc<dyn Trait>`, `From` impls |

## Run it in the benchmark harness

From the repo root, `./run.sh --only rust` builds the image and benchmarks it in a container
capped at 4 CPU cores / 4 GiB RAM. The `Dockerfile` here builds with the **repo root as context**
(the image holds no data; it connects to the shared Postgres started by `db/postgres.sh start`):

```sh
docker build -f demo-rust/Dockerfile -t bfc-rust:bench .   # from the repo root
```

## Build & run natively

```sh
# one-time, if rust is not installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# from THIS directory
cargo build --release

# needs the Postgres from db/postgres.sh (127.0.0.1:5432, database `demo`)
./target/release/demo-rust
```

Overridable via env: `DATABASE_URL` (default `postgres://bench:bench@127.0.0.1:5432/demo`;
`run.sh` builds it from `PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE` when unset),
`PORT` (default `8081`), `DB_POOL_SIZE` (pool `max_connections`, default `32`),
`RUST_LOG` (default `warn`; `debug` turns on per-request tracing).

```sh
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo PORT=8081 ./target/release/demo-rust
```

## Endpoints

Mounted at both `/...` and `/api/...` so either `ab` command shape in the root README works.

| Method | Path | Notes |
|---|---|---|
| GET | `/contents` | `?page=1&size=20`, also accepts `page_size` / `pageSize` |
| GET | `/contents/{id}` | 404 when missing |
| PUT | `/contents/{id}` | body `{"content": "..."}`, 1-1000 chars; 404 when missing |
| GET | `/categories` | all 100 rows, each with its full parent chain |
| GET | `/healthz` | 204 |

Defaults: page 1, size 20. `size` outside 1-100 is rejected with 400, like the Go and .NET demos.
Errors are JSON: `{"error": "validation_failed", "details": [{"field": "size", "rule": "range"}]}`.
Ordered by `id ASC`.
No `COUNT(*)` is issued — the same choice the Hibernate (`Slice`), Django (`NoCountPagination`)
and Go demos make, so pagination cost stays comparable.

## Tests

Run from the **repo root**:

```sh
./test.sh rust
```

This builds the `test` stage of `demo-rust/Dockerfile` (toolchain, dev-dependencies, sources) and
runs `cargo test` in a fresh container against `DATABASE_URL`, which test.sh points at a fresh clone
of `demo_template` (`test_rust`), so the exit code is the result. A plain
`docker build -f demo-rust/Dockerfile .` still builds only the runtime image.

`src/tests.rs` drives the real router, services and SeaORM repositories in-process
(`tower::ServiceExt::oneshot`) against the database in `DATABASE_URL`. The same 16 cases exist in
every demo, and each one compares the full literal JSON body. The tests run in parallel; the one
write (`update_content` on content 2) holds a lock exclusively and restores the row afterwards, so
no other test sees it.

Local dev with a Rust toolchain: `db/postgres.sh reset dev_rust`, then
`DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/dev_rust cargo test` in this directory.

## Benchmark command

```sh
ab -n 10000 -c 1     http://127.0.0.1:8081/api/contents
ab -n 10000 -c 10    http://127.0.0.1:8081/api/contents
ab -n 10000 -c 100   http://127.0.0.1:8081/api/contents
ab -n 10000 -c 1000  http://127.0.0.1:8081/api/contents
ab -n 10000 -c 10000 http://127.0.0.1:8081/api/contents
```

## Notes for a fair reading of the numbers

- **Up to three queries per request.** Every category carries its full parent chain to the root.
  `content -> category` is one `LEFT JOIN`; `category -> parent` is a self-referencing FK, which
  SeaORM's typed `and_also_related` cannot alias, so each level up is one batched `IN (...)` query
  until no unknown parent ids remain (3 levels: at most 2 extra). `/categories` is one query; the
  chains are assembled in memory. Prisma and Django produce the same shape for nested relations.
- **Pool size is `DB_POOL_SIZE` (32)** (`max_connections`), the same budget every demo gets; the
  other pool knobs stay at SeaORM/sqlx defaults.
- **`sqlx_logging(false)`** is set. SeaORM logs every statement at debug by default, which would cost
  far more than the other demos' WARN/ERROR-level logging.
- Release profile uses `lto = "fat"`, `codegen-units = 1`. First release build takes a few minutes.
