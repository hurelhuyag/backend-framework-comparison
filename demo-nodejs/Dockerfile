# Build context is the REPO ROOT:
#   docker build -f demo-nodejs/Dockerfile .                                  runtime image (default)
#   docker build -f demo-nodejs/Dockerfile --target test -t bfc-nodejs:test . && docker run --rm bfc-nodejs:test
# The database is PostgreSQL (DATABASE_URL / PG* / DB_POOL_SIZE); the image holds no dataset.

# Sources, all dependencies (incl. dev), generated Prisma client, compiled dist/.
FROM node:22-bookworm-slim AS build
# Prisma's query engine needs OpenSSL to detect the platform.
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /repo/demo-nodejs
COPY demo-nodejs/package.json demo-nodejs/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY demo-nodejs/ ./
# Only the environment (DATABASE_URL / DB_POOL_SIZE) configures the database, never a local .env.
RUN rm -f .env
RUN npx prisma generate && npm run build

# Endpoint tests against the database in DATABASE_URL (test.sh passes a fresh clone). Exit code = test result.
FROM build AS test
CMD ["npm", "test"]

# Production dependencies only (the generated client in node_modules/.prisma survives the prune).
FROM build AS prod-deps
RUN npm prune --omit=dev

FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app/demo-nodejs
COPY --from=prod-deps /repo/demo-nodejs/package.json /repo/demo-nodejs/run.sh ./
COPY --from=prod-deps /repo/demo-nodejs/node_modules ./node_modules
COPY --from=prod-deps /repo/demo-nodejs/prisma ./prisma
COPY --from=prod-deps /repo/demo-nodejs/dist ./dist
ENV NODE_ENV=production
ENV DATABASE_URL="postgres://bench:bench@127.0.0.1:5432/demo" \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
ENV PORT=3000
EXPOSE 3000
CMD ["./run.sh", "start"]
