# Build context is the REPO ROOT:
#   docker build -f demo-bun/Dockerfile .                                    runtime image (default)
#   ../test.sh bun                                                           test stage, against PostgreSQL
# The test container needs PostgreSQL: ../test.sh starts it and passes DATABASE_URL + PG*.

# Sources and dev dependencies (types, tsc). The app itself has no dependencies: Bun.serve and
# Bun.SQL are built in, and Bun runs the .ts files directly, so there is no compile step.
FROM oven/bun:1-slim AS build
WORKDIR /repo/demo-bun
COPY demo-bun/package.json demo-bun/bun.lock ./
RUN bun install --frozen-lockfile
COPY demo-bun/ ./
RUN bun run typecheck

# Endpoint tests against the database in DATABASE_URL (a fresh clone from ../test.sh). Exit code = test result.
FROM build AS test
CMD ["bun", "test"]

FROM oven/bun:1-slim
WORKDIR /app/demo-bun
COPY demo-bun/package.json demo-bun/run.sh ./
COPY demo-bun/src ./src
ENV NODE_ENV=production
ENV DATABASE_URL="postgres://bench:bench@127.0.0.1:5432/demo" \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
ENV PORT=3003
EXPOSE 3003
CMD ["./run.sh", "start"]
