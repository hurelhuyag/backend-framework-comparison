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
| ORM           | gorm.io/gorm + sqlite driver (cgo)        |
| Logging       | log/slog (JSON), GORM bridged to slog     |
| Config        | caarlos0/env                              |
| DI / mapping  | constructor injection, hand-written mappers |

Environment: `PORT` (8080), `DEMO_DB` (demo.sqlite), `LOG_LEVEL` (WARN; DEBUG enables the access log).

```sh
CGO_ENABLED=1 go build -ldflags="-s -w" -o myapp ./cmd/server
./myapp
```
