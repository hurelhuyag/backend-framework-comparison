# Build context is the REPO ROOT:
#   docker build -f demo-bun-hono/Dockerfile .                                    runtime image (default)
#   ../test.sh bun-hono                                                                    test stage, against PostgreSQL
# The test container needs PostgreSQL: ../test.sh starts it and passes DATABASE_URL + PG*.

# Sources and all dependencies (incl. dev). Bun runs the .ts files directly, so there is no compile step.
FROM oven/bun:1-slim AS build
WORKDIR /repo/demo-bun-hono
COPY demo-bun-hono/package.json demo-bun-hono/bun.lock ./
RUN bun install --frozen-lockfile
COPY demo-bun-hono/ ./
RUN bun run typecheck

# Endpoint tests against the database in DATABASE_URL (a fresh clone from ../test.sh). Exit code = test result.
FROM build AS test
CMD ["bun", "test"]

# Production dependencies only.
FROM oven/bun:1-slim AS prod-deps
WORKDIR /repo/demo-bun-hono
COPY demo-bun-hono/package.json demo-bun-hono/bun.lock ./
RUN bun install --frozen-lockfile --production

FROM oven/bun:1-slim
WORKDIR /app/demo-bun-hono
COPY --from=prod-deps /repo/demo-bun-hono/node_modules ./node_modules
COPY demo-bun-hono/package.json demo-bun-hono/run.sh ./
COPY demo-bun-hono/src ./src
ENV NODE_ENV=production
ENV DATABASE_URL="postgres://bench:bench@127.0.0.1:5432/demo" \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
ENV PORT=3001
EXPOSE 3001
CMD ["./run.sh", "start"]
