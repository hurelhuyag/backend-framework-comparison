# Build context is the REPO ROOT: docker build -f demo-go/Dockerfile .
FROM golang:1-bookworm AS build
WORKDIR /repo/demo-go
COPY demo-go/go.mod demo-go/go.sum ./
RUN go mod download
COPY demo-go/cmd ./cmd
COPY demo-go/internal ./internal
RUN CGO_ENABLED=1 go build -ldflags="-s -w" -o myapp ./cmd/server

# ../test.sh go: runs the endpoint tests against this container's own copy of the dataset.
FROM build AS test
COPY demo.sqlite /repo/demo.sqlite
CMD ["go", "test", "-count=1", "./..."]

FROM debian:bookworm-slim
WORKDIR /app/demo-go
COPY demo-go/run.sh ./run.sh
COPY --from=build /repo/demo-go/myapp ./myapp
COPY demo.sqlite /app/demo.sqlite
EXPOSE 8080
CMD ["./run.sh", "start"]
