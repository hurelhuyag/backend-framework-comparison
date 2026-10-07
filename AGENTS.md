# AGENTS.md

Guidance for anyone, human or AI agent, changing this repo, especially to make a demo faster.

## What this project measures

Each `demo-*/` is a **small version of how a big production project in that ecosystem is built**:
the usual framework, ORM, layering, validation, error handling and logging. The benchmark
compares those realistic stacks doing **the same work** against the **same data**.

So the question an optimization must pass is:

> Would a competent team ship this in a large production codebase in that ecosystem?

If yes, it is welcome. If it only makes sense because this is a benchmark, it is not.

## Repo layout

| Path | What it is |
|---|---|
| `db/generate.sql` | Builds `demo.sqlite` deterministically. The only way the dataset changes. |
| `demo.sqlite` | The dataset: 100 categories in 3 levels, 100,000 contents, WAL mode. |
| `demo-*/` | One stack each. GraalVM has no source of its own; it compiles `demo-hibernate-sqlite`. |
| `bench/mixed.js` | The k6 load mix, shared by every demo. |
| `run.sh` | Benchmark harness: builds, runs and measures each demo, writes the report. |
| `test.sh` | Runs every demo's endpoint tests, each in its own container. |
| `report.adoc`, `README.adoc` | Generated results. Never edit between the `GENERATED REPORT` markers. |

## The contract every demo implements

**Endpoints.** Each demo keeps its own URL spelling, which `demo-*/run.sh meta` publishes.

- `GET` contents list: paginated and ordered by id, with no `COUNT(*)`.
  - Defaults are page 1 and size 20, capped at 100.
- `GET` content by id.
- `PUT` content by id with `{"content": "..."}`: rewrites only the text.
  - This keeps the row count constant across runs.
- `GET` categories: all 100.

**Data rules.**

- Every nested category carries its **full parent chain to the root**.
- The chain is loaded with **eager loading**: joins or batched `IN (...)` queries, one per level.
  - Never a query per row (N+1).
  - Never a lazy load during serialization.
- The response maps entities to DTOs or views. ORM entities are not serialized directly.

**Behaviour rules.**

- Invalid input gets a 4xx JSON error, never a 500 or a silently wrong answer.
  - This covers a non-numeric id, a bad page size and a missing or empty `content`.
- Unknown ids get 404.
- Log level is WARN by default, with no per-request logging at that level.

**Runtime contract.** Each demo has:

- **`run.sh`** with four subcommands:
  - `meta` prints `NAME`, `STACK`, `PORT`, `BENCH_PATH`, `LIST_PATH`, `ITEM_PATH` and `CATEGORIES_PATH`;
  - `check`;
  - `build`;
  - `start` runs the server in the foreground on `$PORT` against `$DEMO_DB`.
- **`Dockerfile`**, built with the **repo root** as context:
  - a `test` stage placed before the final stage;
  - a final stage that copies `demo.sqlite` to `/app/demo.sqlite` and ends in `./run.sh start`.

## Optimizing: allowed vs. not allowed

**Allowed** (what production teams actually do):

- Release builds and production runtime modes.
- Runtime flags: GC, JIT, AOT/native, thread or worker counts.
- Connection pool sizing, prepared-statement caching, HTTP server settings.
- A better eager-loading strategy within the ORM, e.g. one joined query instead of batched queries.
- Upgrading the framework, ORM or runtime to a current stable version.
- Fixing real bugs: locking errors, resource limits, N+1 queries, misconfiguration.

**Not allowed** (the result would stop being comparable or realistic):

- **Caching responses or query results** in memory, or precomputing JSON. Every request must hit
  the database.
- **Bypassing the ORM** with hand-written SQL for the endpoints. Every demo uses its ecosystem's
  standard ORM.
- **Removing layers**, validation, error handling or DTO mapping to save time.
- **Special-casing benchmark URLs** or page sizes.
- **Changing the dataset**, the load mix (`bench/mixed.js`) or the response shapes.
  - These change for every demo or not at all.
- **Weakening durability for one demo**, e.g. `PRAGMA synchronous=OFF` or a different journal mode.
- **Giving one demo different limits.** CPU, memory, ulimits and container settings live in
  `run.sh` and are identical for every container.

Cross-cutting changes (dataset, load mix, harness, limits) apply to **all demos at once**, followed
by a full re-run.

## Tests

Every demo has the same **16 endpoint tests**, with the same names in the same order:

- `list_default`, `list_page_2_size_2`, `list_past_the_end`, `list_size_zero`;
- `item_in_root_category`, `item_in_level_2_category`, `item_in_level_3_category`,
  `item_without_category`, `item_not_found`, `item_non_numeric_id`;
- `update_content`, `update_empty_content`, `update_missing_content_field`,
  `update_malformed_json`, `update_not_found`;
- `categories`.

```sh
./test.sh            # all demos, each in its own container with its own copy of demo.sqlite
./test.sh go rust    # just those
```

Rules for the tests:

- They are for **humans to read**. One test per case: the request, the status, then the **full
  expected JSON written out literally**, compared exactly.
  - No loops or tables.
  - No helpers that build expected bodies.
- They run against a **copy** of the real `demo.sqlite`. They never write to the repo's file.
- When behaviour changes on purpose, derive the new expected bodies from SQL queries on
  `demo.sqlite`, not by pasting the app's output. Otherwise a bug becomes the expected answer.
- `./test.sh` must pass before you benchmark.

## Benchmarking

1. Commit first. A run on a clean tree is tagged `bench/<date>-<n>`, so the numbers can be
   reproduced.
2. Run on an otherwise idle machine:
   ```sh
   ./run.sh                    # all demos, in Docker, 4 CPUs / 4 GiB each
   ./run.sh --only go,rust     # partial run; updates only those rows
   ./run.sh --report-only      # rebuild the report from stored results
   ```
3. Only one server runs at a time. Each one starts from a fresh container with its own copy of
   the dataset. `--native` mode hands each demo a fresh temporary copy instead.
4. Check the per-demo server logs in `.bench-logs/<name>.server.log` before trusting a number.
   - A `*` in the report or a Failed level often points at a setup problem, e.g. locking errors
     or file-descriptor limits, rather than the framework itself.
5. In the pull request, state what changed, why a production team would do the same, and the
   before/after numbers from the same machine.

## Known open issues

These come from the 2026-10-06 run. Fix them the allowed way and re-run.

- **Rust is capped by the open-file limit.**
  - Docker containers start with a soft `nofile` limit of 1024. Other runtimes raise it
    themselves; the Rust binary does not.
  - Result: `Too many open files` at c≥1000.
  - Fix in `run.sh` for every container: `--ulimit nofile=65535:65535`.
- **Java and GraalVM writes fail with `SQLITE_BUSY`.**
  - The update reads and then writes inside one transaction, which SQLite rejects when another
    writer gets in between.
  - Fix: a single `@Modifying` UPDATE query, then the read.
- **.NET ignores paging when `page` is set.**
  - Any `page` query key makes MVC bind the whole `PageQuery` with a `page.` prefix, so the
    request gets page 1 with size 20.
  - The benchmark URL only uses `size`, so the numbers are unaffected.
- **Most PUT responses leave out the category.**
  - Every demo except Python returns `category` as `null`, or omits the key, in the PUT response,
    while GET includes it.
- **Java lists newest first with 0-based pages.**
  - Every other demo lists oldest first with 1-based pages.
  - The tests pin this as Spring Data's convention.
- **PHP and Python fail at c=10000.**
  - This is a real limit of their process/worker model, not a bug.
