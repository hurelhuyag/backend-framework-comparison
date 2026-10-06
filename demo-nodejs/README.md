# demo-nodejs: NestJS + Prisma (SQLite)

A small NestJS service laid out the way a production NestJS codebase is: feature modules,
constructor DI, controller -> service -> repository, validated request DTOs, and explicitly
mapped response DTOs. Runs on Nest's default Express adapter.

```
src/
  main.ts                    bootstrap: logger levels, shutdown hooks, listen on $PORT (3000)
  app.setup.ts               global prefix /api + ValidationPipe (whitelist, transform); shared with tests
  app.module.ts              PrismaModule, CategoryModule, ContentModule
  common/log-levels.ts       LOG_LEVEL -> Nest log levels (default: warn)
  prisma/                    PrismaModule (global) + PrismaService (connect / disconnect on shutdown)
  category/                  GET /api/categories
    category-chain.ts        Prisma include for the full parent chain + row type
    dto/category.response.ts
  content/                   GET /api/contents, GET|PUT /api/contents/:id
    dto/list-contents.query.ts      page >= 1, 1 <= pageSize <= 100 (ints)
    dto/update-content.request.ts   { content: non-empty string }
    dto/content.response.ts
test/
  api.test.ts                the 16 endpoint cases shared by every demo
  test-app.ts                boots AppModule on a temp copy of demo.sqlite
```

## Run

```sh
./run.sh build     # npm install, prisma generate, tsc -> dist/
./run.sh start     # node dist/main.js on $PORT (3000), DATABASE_URL = repo-root demo.sqlite
```

or by hand:

```sh
npm install
npx prisma generate
npm run build
DATABASE_URL=file:$PWD/../demo.sqlite npm start
```

Docker (build context is the repo root):

```sh
docker build -f demo-nodejs/Dockerfile -t bfc-nodejs .
docker run --rm -p 3000:3000 bfc-nodejs
```

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
sources + `test/`, and its own copy of `demo.sqlite` at `/repo/demo.sqlite`) and runs `npm test` in a
throw-away container, so the exit code is the result. Nothing is mounted from the host. A plain
`docker build -f demo-nodejs/Dockerfile .` still builds only the runtime image.

`test/api.test.ts` holds the 16 endpoint cases shared by every demo in this repo (Jest + ts-jest +
supertest). `test/test-app.ts` copies `../demo.sqlite` to a temp file, points `DATABASE_URL` at the copy,
and boots the real `AppModule` with the same global setup as `main.ts`. The one write (`update_content`)
is undone after each test. Expected bodies are written out literally and pin current behaviour.

Running `npm test` directly on the host also works (after `npm install && npx prisma generate`); it
reads the repo-root `demo.sqlite` only to copy it.
