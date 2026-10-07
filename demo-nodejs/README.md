# demo-nodejs: NestJS + Prisma (PostgreSQL)

A small NestJS service laid out the way a production NestJS codebase is: feature modules,
constructor DI, controller -> service -> repository, validated request DTOs, and explicitly
mapped response DTOs. Runs on Nest's default Express adapter.

```
src/
  main.ts                    bootstrap: logger levels, shutdown hooks, listen on $PORT (3000)
  app.setup.ts               global prefix /api + ValidationPipe (whitelist, transform); shared with tests
  app.module.ts              PrismaModule, CategoryModule, ContentModule
  common/log-levels.ts       LOG_LEVEL -> Nest log levels (default: warn)
  prisma/                    PrismaModule (global) + PrismaService (pool size, connect / disconnect on shutdown)
  category/                  GET /api/categories
    category-chain.ts        Prisma include for the full parent chain + row type
    dto/category.response.ts
  content/                   GET /api/contents, GET|PUT /api/contents/:id
    dto/list-contents.query.ts      page >= 1, 1 <= pageSize <= 100 (ints)
    dto/update-content.request.ts   { content: non-empty string }
    dto/content.response.ts
test/
  api.test.ts                the 16 endpoint cases shared by every demo
  test-app.ts                boots AppModule on the database in DATABASE_URL
```

## Run

```sh
./run.sh build     # npm install, prisma generate, tsc -> dist/
./run.sh start     # node dist/main.js on $PORT (3000) against $DATABASE_URL
```

or by hand:

```sh
npm install
npx prisma generate
npm run build
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo npm start
```

Docker (build context is the repo root):

```sh
docker build -f demo-nodejs/Dockerfile -t bfc-nodejs .
docker run --rm --network host bfc-nodejs
```

Database: PostgreSQL, read from `DATABASE_URL` (default `postgres://bench:bench@127.0.0.1:5432/demo`,
the `bfc-postgres` server from `db/postgres.sh`). The image holds no data. Prisma's pool size is the
`connection_limit` URL parameter; `PrismaService` appends `connection_limit=$DB_POOL_SIZE` (default 32)
unless the URL already sets one. The `PG*` variables are exported for parity with the other demos.

Logging uses Nest's built-in `Logger`. The default `LOG_LEVEL=warn` logs warnings and errors
only (no per-request logs); `LOG_LEVEL=debug` also logs every SQL statement Prisma sends.

Errors are Nest's standard JSON, e.g. `{"statusCode":404,"message":"Content 7 not found","error":"Not Found"}`.
A non-integer `:id`, `page` or `pageSize`, a `page` below 1, a `pageSize` outside 1..100, or a
missing/empty `content` gives 400.

```sh
ab -n 10000 -c 1 http://localhost:3000/api/contents?pageSize=20
```

## Tests

From the repo root:

```sh
./test.sh nodejs
```

This builds the `test` stage of `demo-nodejs/Dockerfile` (dev dependencies, generated Prisma client,
sources + `test/`) and runs `npm test` in a throw-away container against a fresh clone of the
dataset (`test_nodejs`, passed as `DATABASE_URL`), so the exit code is the result. Nothing is mounted from the host. A plain
`docker build -f demo-nodejs/Dockerfile .` still builds only the runtime image.

`test/api.test.ts` holds the 16 endpoint cases shared by every demo in this repo (Jest + ts-jest +
supertest). `test/test-app.ts` connects to the database in `DATABASE_URL`
and boots the real `AppModule` with the same global setup as `main.ts`. The one write (`update_content`)
is undone after each test. Expected bodies are written out literally and pin current behaviour.

Running `npm test` directly on the host also works (after `npm install && npx prisma generate`) with
`DATABASE_URL` pointing at a clone of the dataset (`db/postgres.sh reset <name>`).
