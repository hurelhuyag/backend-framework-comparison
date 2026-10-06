# Build context is the REPO ROOT:
#   docker build -f demo-nodejs/Dockerfile .                                  runtime image (default)
#   docker build -f demo-nodejs/Dockerfile --target test -t bfc-nodejs:test . && docker run --rm bfc-nodejs:test
# The paths mirror the repo (/repo/demo-nodejs + /repo/demo.sqlite), so ../demo.sqlite resolves the same way.

# Sources, all dependencies (incl. dev), generated Prisma client, compiled dist/.
FROM node:22-bookworm-slim AS build
# Prisma's query engine needs OpenSSL to detect the platform.
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /repo/demo-nodejs
COPY demo-nodejs/package.json demo-nodejs/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY demo-nodejs/ ./
# .env (if present locally) hardcodes a host path; DATABASE_URL wins instead.
RUN rm -f .env
RUN npx prisma generate && npm run build

# Endpoint tests against this container's own copy of demo.sqlite. Exit code = test result.
FROM build AS test
COPY demo.sqlite /repo/demo.sqlite
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
COPY demo.sqlite /app/demo.sqlite
ENV NODE_ENV=production
ENV DATABASE_URL="file:/app/demo.sqlite"
ENV PORT=3000
EXPOSE 3000
CMD ["./run.sh", "start"]
