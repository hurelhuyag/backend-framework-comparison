# demo-rust — Rust / Axum / SeaORM / SQLite

Sixth-language entry in the comparison: **Axum 0.8** (most-downloaded Rust web framework) +
**SeaORM 2.0** (the popular async Rust ORM) against the same `demo.sqlite` as every other demo.

SeaORM is used deliberately instead of raw `sqlx`. Every other demo in this repo goes through an ORM
(GORM, Hibernate, Prisma, Eloquent, Django ORM), so hand-written SQL here would measure a different
workload and flatter Rust for the wrong reason.

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

Overridable via env: `DATABASE_URL` (default `sqlite://demo.sqlite`), `PORT` (default `8081`).

```sh
DATABASE_URL=sqlite://demo.sqlite PORT=8081 ./demo-rust/target/release/demo-rust
```

## Endpoints

Mounted at both `/...` and `/api/...` so either `ab` command shape in the root README works.

| Method | Path | Notes |
|---|---|---|
| GET | `/contents` | `?page=1&size=20`, also accepts `page_size` / `pageSize` |
| GET | `/contents/{id}` | 404 when missing |
| GET | `/categories` | all 110 rows, each with its parent |

Defaults match the Django/NextJS demos: page 1, size 20, capped at 100. Ordered by `id ASC`.
No `COUNT(*)` is issued — the same choice the Hibernate (`Slice`), Django (`NoCountPagination`)
and Go demos make, so pagination cost stays comparable.

## Test command

```sh
ab -n 10000 -c 1     http://127.0.0.1:8081/api/contents
ab -n 10000 -c 10    http://127.0.0.1:8081/api/contents
ab -n 10000 -c 100   http://127.0.0.1:8081/api/contents
ab -n 10000 -c 1000  http://127.0.0.1:8081/api/contents
ab -n 10000 -c 10000 http://127.0.0.1:8081/api/contents
```

## Notes for a fair reading of the numbers

- **Two queries per request.** `content -> category` is one `LEFT JOIN`; `category -> parent` is a
  self-referencing FK, which SeaORM's typed `and_also_related` cannot alias, so parents are fetched
  in a second batched `IN (...)` query. Prisma and Django produce the same shape for a nested
  relation; Hibernate's `@NamedEntityGraph` does it in a single join, so it has a small edge here.
- **Pool size is 16** (`max_connections`), vs Hikari's default 10 in the Spring demo. Worth aligning
  before publishing a table — SQLite read concurrency is sensitive to this.
- **`sqlx_logging(false)`** is set. SeaORM logs every statement at debug by default, which would cost
  far more than the other demos' WARN/ERROR-level logging.
- Release profile uses `lto = "fat"`, `codegen-units = 1`. First release build takes a few minutes.
