# demo-bun — Bun / Hono / Drizzle / SQLite

Ninth entry in the comparison, and the second JavaScript one. It exists to separate
*"JavaScript is slow"* from *"this particular JS stack is heavy"*.

`demo-nodejs` is Node + NestJS + Prisma: a DI/decorator framework talking to a separate Rust
query engine. This one is the opposite end of the same ecosystem — Bun (JavaScriptCore), Hono
(minimal router) and Drizzle over `bun:sqlite`, which is compiled into the runtime.

## Read the two JS rows with care

They differ in **three** variables at once — runtime, framework and data layer — so the gap
between them does **not** measure "Bun vs Node". Attributing it to the runtime alone would need
a third row holding two of the three fixed (Node + Hono + Drizzle).

Also note **Drizzle is a typed query builder, not a full ORM** like the Hibernate/EF Core/Prisma/
Eloquent/Django/SeaORM/GORM rows. There is no identity map, dirty tracking or lazy loading. It
can express the nested `content -> category -> parent` load, and here it does so with explicit
aliased `LEFT JOIN`s, but it does strictly less work per request than a real ORM.

## Run it in the benchmark harness

```sh
./run.sh --only bun            # from the repo root
```

## Build & run natively

```sh
cd demo-bun && bun install
DEMO_DB=../demo.sqlite PORT=8084 bun run src/index.ts
```

## Endpoints

Mounted at both `/...` and `/api/...`.

| Method | Path | Notes |
|---|---|---|
| GET | `/contents` | `?page=1&size=20`, also accepts `page_size` / `pageSize` |
| GET | `/contents/{id}` | 404 when missing |
| PUT | `/contents/{id}` | `{"content": "..."}`, zod-validated |
| GET | `/categories` | all 110 rows, each with its parent |

Response shape matches `demo-nodejs` (`{meta, data}`) so the two JS rows are directly comparable.

## Notes

- **One statement per read.** Aliased `LEFT JOIN`s resolve the whole chain, same as Hibernate's
  fetch joins. No `COUNT(*)`.
- **Writes are a single `UPDATE`.** No read-modify-write, so there is no read→write lock upgrade
  and `busy_timeout=5000` (set in `src/db/client.ts`) genuinely applies — unlike the Java demo,
  where the upgrade conflict made `busy_timeout` useless.
