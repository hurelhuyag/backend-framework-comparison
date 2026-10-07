# Build context is the REPO ROOT: docker build -f demo-bun/Dockerfile .
FROM oven/bun:1-slim AS build
WORKDIR /src
COPY demo-bun/package.json demo-bun/tsconfig.json ./
RUN bun install
COPY demo-bun/src ./src
# Bundled ahead of time, mirroring demo-nodejs's tsc step, so startup does no transpiling.
RUN bun build src/index.ts --target=bun --outfile=dist/server.js

FROM oven/bun:1-slim
WORKDIR /app/demo-bun
COPY --from=build /src/dist ./dist
COPY demo-bun/run.sh ./
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8084
EXPOSE 8084
CMD ["./run.sh", "start"]
