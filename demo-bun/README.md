# demo-bun: Bun with no framework and no ORM (PostgreSQL)

The same API as the other demos (same paths, query params and response bodies), written with only
what Bun ships: `Bun.serve` routes for HTTP and `Bun.SQL` for PostgreSQL, with plain SQL. It has
no runtime dependencies at all. Compare it with `demo-bun-hono`, the same runtime with Hono, zod
and Drizzle on top.

```
src/
  index.ts      primary + WORKERS (4) processes sharing $PORT (3003) through reusePort;
                each gets DB_POOL_SIZE / WORKERS connections
  app.ts        Bun.serve routes, hand-written validation, JSON 404 + error handler; shared with tests
  db.ts         Bun.SQL pool and the four queries, as SQL
test/
  api.test.ts   the 16 endpoint cases shared by every demo (bun test, over a real socket)
```

One statement per request. A page of contents is a single `SELECT` with three `LEFT JOIN`s on
`category` (the data has at most 3 levels), nested into category -> parent -> parent in
TypeScript. Drizzle in `demo-bun-hono` instead builds the JSON inside PostgreSQL with
`LEFT JOIN LATERAL` + `row_to_json`.

Errors use the same `{statusCode, message, error}` shape as the other Node/Bun demos; validation
messages are hand-written, e.g.
`{"statusCode":400,"message":"pageSize must be an integer from 1 to 100","error":"Bad Request"}`.

## Run

Needs the PostgreSQL server from `../db/postgres.sh start`. Connection settings come from
`DATABASE_URL` (default `postgres://bench:bench@127.0.0.1:5432/demo`), the pool size from
`DB_POOL_SIZE` (32, split across workers) and the process count from `WORKERS` (4).

```sh
./run.sh build     # bun install (type definitions and tsc only)
./run.sh start     # bun src/index.ts on $PORT (3003)
```

Docker (build context is the repo root):

```sh
docker build -f demo-bun/Dockerfile -t bfc-bun .
docker run --rm --network host bfc-bun
```

## Tests

```sh
./test.sh bun     # from the repo root: Docker, against a fresh clone of demo_template
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/test_bun bun test   # on the host
```
