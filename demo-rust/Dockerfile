# Build context is the REPO ROOT: docker build -f demo-rust/Dockerfile .
FROM rust:1-slim-bookworm AS build
WORKDIR /src
COPY demo-rust/Cargo.toml demo-rust/Cargo.lock ./
# Warm the dependency cache against a stub binary so source edits do not refetch crates.
RUN mkdir src && echo 'fn main() {}' > src/main.rs && cargo build --release && rm -rf src
COPY demo-rust/src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim
WORKDIR /app/demo-rust
COPY demo-rust/run.sh ./run.sh
COPY --from=build /src/target/release/demo-rust ./target/release/demo-rust
COPY demo.sqlite /app/demo.sqlite
ENV PORT=8081
EXPOSE 8081
CMD ["./run.sh", "start"]
