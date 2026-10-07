# Build context is the REPO ROOT: docker build -f demo-rust/Dockerfile .
FROM rust:1-slim-bookworm AS build
WORKDIR /src
COPY demo-rust/Cargo.toml demo-rust/Cargo.lock ./
# Warm the dependency cache against a stub binary so source edits do not refetch crates.
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo build --release && rm -rf src
COPY demo-rust/src ./src
RUN touch src/main.rs && cargo build --release

# Endpoint tests: ./test.sh rust (from the repo root). Never built by a plain `docker build`.
# Tests are compiled here and run by CMD against the database in DATABASE_URL (test.sh passes a fresh
# clone of demo_template), so the exit code is the result.
FROM rust:1-slim-bookworm AS test
WORKDIR /repo/demo-rust
COPY demo-rust/Cargo.toml demo-rust/Cargo.lock ./
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo test --no-run && rm -rf src
COPY demo-rust/src ./src
RUN touch src/main.rs && cargo test --no-run
CMD ["cargo", "test"]

FROM debian:bookworm-slim
WORKDIR /app/demo-rust
COPY demo-rust/run.sh ./run.sh
COPY --from=build /src/target/release/demo-rust ./target/release/demo-rust
ENV PORT=8081 \
    DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
EXPOSE 8081
CMD ["./run.sh", "start"]
