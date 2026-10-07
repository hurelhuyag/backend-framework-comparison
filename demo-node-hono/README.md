# demo-node-hono: Node + Hono + Drizzle (PostgreSQL, node-postgres)

The same API as `demo-nodejs` (same paths, query params and response bodies), written the way a
small Hono service usually is: route modules mounted on one app, zod validation through
`@hono/zod-validator`, and Drizzle 1.0 relational queries, served by
`@hono/node-server` and compiled with tsc. `demo-bun-hono` is the same code on Bun.

```
src/
  index.ts                  @hono/node-server on $PORT (3002), DATABASE_URL (PostgreSQL)
  app.ts                    createApp(db): routes under /api, JSON 404 + error handler; shared with tests
  env.ts                    Hono context type (c.var.db)
  validate.ts               zValidator whose failures are {statusCode: 400, message: [...], error}
  db/
    schema.ts               category, content tables (mirrors db/generate.sql)
    relations.ts            defineRelations: category.parent (self), content.category
    client.ts               pg.Pool (node-postgres) + drizzle; pool of DB_POOL_SIZE; LOG_LEVEL=debug logs SQL
    category-chain.ts       `with` for the full parent chain + response mapping
  routes/
    categories.ts           GET /api/categories
    contents.ts             GET /api/contents, GET|PUT /api/contents/:id
test/
  api.test.ts               the 16 endpoint cases shared by every demo (vitest)
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
./run.sh build     # npm install, tsc -> dist/
./run.sh start     # node dist/index.js on $PORT (3002)
```

Docker (build context is the repo root):

```sh
docker build -f demo-node-hono/Dockerfile -t bfc-node-hono .
docker run --rm --network host bfc-node-hono
```

Errors use the same `{statusCode, message, error}` shape as `demo-nodejs`. Validation messages are zod's,
e.g. `{"statusCode":400,"message":["pageSize: Too small: expected number to be >=1"],"error":"Bad Request"}`.

## Tests

```sh
./test.sh node-hono    # from the repo root: Docker, against a fresh clone of demo_template
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/test_node_hono npm test   # on the host
```
