# Build context is the REPO ROOT:
#   docker build -f demo-node-hono/Dockerfile .                                     runtime image (default)
#   ../test.sh node-hono                                                                    test stage, against PostgreSQL
# The test container needs PostgreSQL: ../test.sh starts it and passes DATABASE_URL + PG*.

# Sources, all dependencies (incl. dev), compiled dist/.
FROM node:24-bookworm-slim AS build
WORKDIR /repo/demo-node-hono
COPY demo-node-hono/package.json demo-node-hono/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY demo-node-hono/ ./
RUN npm run build

# Endpoint tests against the database in DATABASE_URL (a fresh clone from ../test.sh). Exit code = test result.
FROM build AS test
CMD ["npm", "test"]

# Production dependencies only.
FROM build AS prod-deps
RUN npm prune --omit=dev

FROM node:24-bookworm-slim
WORKDIR /app/demo-node-hono
COPY --from=prod-deps /repo/demo-node-hono/package.json /repo/demo-node-hono/run.sh ./
COPY --from=prod-deps /repo/demo-node-hono/node_modules ./node_modules
COPY --from=prod-deps /repo/demo-node-hono/dist ./dist
ENV NODE_ENV=production
ENV DATABASE_URL="postgres://bench:bench@127.0.0.1:5432/demo" \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
ENV PORT=3002
EXPOSE 3002
CMD ["./run.sh", "start"]
