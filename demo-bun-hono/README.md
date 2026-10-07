# demo-bun-hono: Bun + Hono + Drizzle (PostgreSQL, Bun.SQL)

The same API as `demo-nodejs` (same paths, query params and response bodies), written the way a
small Hono service usually is: route modules mounted on one app, zod validation through
`@hono/zod-validator`, and Drizzle 1.0 relational queries. Bun runs the TypeScript sources
directly, with no build step. `demo-node-hono` is the same code on Node.

```
src/
  index.ts                  Bun.serve on $PORT (3001), DATABASE_URL (PostgreSQL)
  app.ts                    createApp(db): routes under /api, JSON 404 + error handler; shared with tests
  env.ts                    Hono context type (c.var.db)
  validate.ts               zValidator whose failures are {statusCode: 400, message: [...], error}
  db/
    schema.ts               category, content tables (mirrors db/generate.sql)
    relations.ts            defineRelations: category.parent (self), content.category
    client.ts               Bun.SQL (Bun's built-in PostgreSQL client) + drizzle; pool of DB_POOL_SIZE; LOG_LEVEL=debug logs SQL
    category-chain.ts       `with` for the full parent chain + response mapping
  routes/
    categories.ts           GET /api/categories
    contents.ts             GET /api/contents, GET|PUT /api/contents/:id
test/
  api.test.ts               the 16 endpoint cases shared by every demo (bun test)
  test-app.ts               builds the app on the database in DATABASE_URL
```

Drizzle pins `1.0.0-rc.4`, the newest 1.0 build at the time of writing (npm `latest` is still 0.45).
Each request is a single SQL statement: Drizzle loads the category and its parent chain as nested
`LEFT JOIN LATERAL` subqueries that build the JSON with `row_to_json`.

## Run

Needs the PostgreSQL server from `../db/postgres.sh start`. Connection settings come from
`DATABASE_URL` (default `postgres://bench:bench@127.0.0.1:5432/demo`) and the pool size from
`DB_POOL_SIZE` (32).

```sh
./run.sh build     # bun install
./run.sh start     # bun src/index.ts on $PORT (3001)
```

Docker (build context is the repo root):

```sh
docker build -f demo-bun-hono/Dockerfile -t bfc-bun-hono .
docker run --rm --network host bfc-bun-hono
```

Errors use the same `{statusCode, message, error}` shape as `demo-nodejs`. Validation messages are zod's,
e.g. `{"statusCode":400,"message":["pageSize: Too small: expected number to be >=1"],"error":"Bad Request"}`.

## Tests

```sh
./test.sh bun-hono     # from the repo root: Docker, against a fresh clone of demo_template
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/test_bun_hono bun test   # on the host
```
