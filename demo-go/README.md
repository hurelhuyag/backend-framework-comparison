# demo-go

Go / Gin / GORM, laid out the way a production Go service usually is:

```
cmd/server/          composition root: config, wiring, graceful shutdown
internal/config/     env config (caarlos0/env)
internal/model/      GORM entities
internal/repository/ persistence (GORM), hides gorm.ErrRecordNotFound
internal/service/    business layer, declares the repository interfaces it needs
internal/handler/    Gin handlers, request/response DTOs, mappers, validation, error mapping
internal/middleware/ cross-cutting: panic recovery, access log (slog)
```

| Concern       | Library                                   |
|---------------|-------------------------------------------|
| HTTP routing  | gin-gonic/gin                             |
| Validation    | go-playground/validator (via Gin binding) |
| ORM           | gorm.io/gorm + postgres driver (pgx)      |
| Logging       | log/slog (JSON), GORM bridged to slog     |
| Config        | caarlos0/env                              |
| DI / mapping  | constructor injection, hand-written mappers |

Environment: `PORT` (8080), `DATABASE_URL` (postgres://bench:bench@127.0.0.1:5432/demo; libpq URL or
key=value DSN, missing parts fall back to `PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE`),
`DB_POOL_SIZE` (32; max open and max idle connections of the database/sql pool), `LOG_LEVEL`
(WARN; DEBUG enables the access log).

```sh
CGO_ENABLED=0 go build -ldflags="-s -w" -o myapp ./cmd/server
./myapp
```

## Tests

`internal/handler/endpoints_test.go` drives every endpoint through the real router, services and
repositories against the PostgreSQL database named by `DATABASE_URL` (`../test.sh go` hands it a
fresh clone of `demo_template`), and compares each response body as a whole JSON document. The one
write (`PUT /contents/2`) is reverted when its test finishes.

```sh
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/dev_go go test ./...
```
