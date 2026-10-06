# demo-rust — Rust / Axum / SeaORM / SQLite

Sixth-language entry in the comparison: **Axum 0.8** (most-downloaded Rust web framework) +
**SeaORM 2.0** (the popular async Rust ORM) against the same `demo.sqlite` as every other demo.

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
| ORM                | sea-orm 2.0 (sqlx-sqlite)                    |
| Logging / tracing  | tracing, tracing-subscriber (JSON, EnvFilter)|
| Errors             | thiserror (app), anyhow (main)               |
| DI / mapping       | constructor injection via `Arc<dyn Trait>`, `From` impls |

## Run it in the benchmark harness

From the repo root, `./run.sh --only rust` builds the image and benchmarks it in a container
capped at 4 CPU cores / 4 GiB RAM. The `Dockerfile` here builds with the **repo root as context**
so it can copy `demo.sqlite` into the image:

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

# run from the REPO ROOT, where demo.sqlite lives
cd .. && ./demo-rust/target/release/demo-rust
```

Overridable via env: `DATABASE_URL` (default `sqlite://demo.sqlite`), `PORT` (default `8081`),
`DB_MAX_CONNECTIONS` (default `16`), `RUST_LOG` (default `warn`; `debug` turns on per-request tracing).

```sh
DATABASE_URL=sqlite://demo.sqlite PORT=8081 ./demo-rust/target/release/demo-rust
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

This builds the `test` stage of `demo-rust/Dockerfile` (toolchain, dev-dependencies, sources and its
own copy of `demo.sqlite` at `/repo/demo.sqlite`) and runs `cargo test` in a fresh container, so the
exit code is the result. Nothing is mounted from the host, so the repo's database is never read or
written. A plain `docker build -f demo-rust/Dockerfile .` still builds only the runtime image.

`src/tests.rs` drives the real router, services and SeaORM repositories in-process
(`tower::ServiceExt::oneshot`), each test against its own temp copy of `../demo.sqlite`. The same 16
cases exist in every demo, and each one compares the full literal JSON body.

Local dev with a Rust toolchain: `cargo test` in this directory (reads `../demo.sqlite`, copies it per test).

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
- **Pool size is 16** (`max_connections`), vs Hikari's default 10 in the Spring demo. Worth aligning
  before publishing a table — SQLite read concurrency is sensitive to this.
- **`sqlx_logging(false)`** is set. SeaORM logs every statement at debug by default, which would cost
  far more than the other demos' WARN/ERROR-level logging.
- Release profile uses `lto = "fat"`, `codegen-units = 1`. First release build takes a few minutes.
