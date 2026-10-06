# Build context is the REPO ROOT: docker build -f demo-go/Dockerfile .
FROM golang:1-bookworm AS build
WORKDIR /src
COPY demo-go/go.mod demo-go/go.sum ./
RUN go mod download
COPY demo-go/cmd ./cmd
COPY demo-go/internal ./internal
RUN CGO_ENABLED=1 go build -ldflags="-s -w" -o myapp ./cmd/server

FROM debian:bookworm-slim
WORKDIR /app/demo-go
COPY demo-go/run.sh ./run.sh
COPY --from=build /src/myapp ./myapp
COPY demo.sqlite /app/demo.sqlite
EXPOSE 8080
CMD ["./run.sh", "start"]
