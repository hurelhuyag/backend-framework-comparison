# Build context is the REPO ROOT: docker build -f demo-nodejs/Dockerfile .
FROM node:22-bookworm-slim AS build
WORKDIR /src
COPY demo-nodejs/package.json demo-nodejs/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY demo-nodejs/ ./
# .env hardcodes an absolute path that does not exist here; DATABASE_URL below wins instead.
RUN rm -f .env
ENV DATABASE_URL="file:/app/demo.sqlite"
RUN npx prisma generate && NODE_ENV=production npm run build

FROM node:22-bookworm-slim
WORKDIR /app/demo-nodejs
COPY --from=build /src ./
COPY demo.sqlite /app/demo.sqlite
ENV DATABASE_URL="file:/app/demo.sqlite"
ENV PORT=3000
EXPOSE 3000
CMD ["./run.sh", "start"]
