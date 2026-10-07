# Build context is the REPO ROOT: docker build -f demo-go/Dockerfile .
FROM golang:1-bookworm AS build
WORKDIR /repo/demo-go
COPY demo-go/go.mod demo-go/go.sum ./
RUN go mod download
COPY demo-go/cmd ./cmd
COPY demo-go/internal ./internal
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o myapp ./cmd/server

# ../test.sh go: runs the endpoint tests against the database given by DATABASE_URL / PG*.
FROM build AS test
CMD ["go", "test", "-count=1", "./..."]

FROM debian:bookworm-slim
WORKDIR /app/demo-go
COPY demo-go/run.sh ./run.sh
COPY --from=build /repo/demo-go/myapp ./myapp
ENV DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32
EXPOSE 8080
CMD ["./run.sh", "start"]
