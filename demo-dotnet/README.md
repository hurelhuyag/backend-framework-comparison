# demo-dotnet — C# / ASP.NET Core / EF Core / SQLite

Seventh entry in the comparison: **ASP.NET Core 10 Minimal APIs** + **EF Core 10** against the same
`demo.sqlite` as every other demo.

EF Core is used rather than Dapper or raw `Microsoft.Data.Sqlite`, for the same reason the Rust demo
uses SeaORM instead of raw `sqlx`: every other demo here goes through a full ORM (Hibernate, GORM,
Prisma, Eloquent, Django ORM, SeaORM), so hand-written SQL would measure a different workload.

## Run it in the benchmark harness

```sh
./run.sh --only dotnet            # from the repo root
```

The `Dockerfile` builds with the **repo root as context** so it can copy `demo.sqlite`:

```sh
docker build -f demo-dotnet/Dockerfile -t bfc-dotnet:bench .
```

## Build & run natively

```sh
cd demo-dotnet
dotnet publish -c Release -o ./publish
cd .. && DEMO_DB=$PWD/demo.sqlite ASPNETCORE_URLS=http://0.0.0.0:8082 ./demo-dotnet/publish/demo-dotnet
```

Overridable via env: `DEMO_DB` (default `demo.sqlite`), `PORT` (default `8082`).

## Endpoints

Mounted at both `/...` and `/api/...`.

| Method | Path | Notes |
|---|---|---|
| GET | `/contents` | `?page=1&size=20`, also accepts `page_size` / `pageSize` |
| GET | `/contents/{id}` | 404 when missing |
| GET | `/categories` | all 110 rows, each with its parent |

Defaults match the Django/NextJS demos: page 1, size 20, capped at 100. Ordered by `id ASC`, and no
`COUNT(*)` is issued.

## Notes for a fair reading of the numbers

- **One query per request.** `Include(...).ThenInclude(...)` resolves `content -> category -> parent`
  in a single SQL statement with two `LEFT JOIN`s, because EF Core aliases the self-referencing join.
  This matches Hibernate's `@NamedEntityGraph` and is *better* than the Rust/Prisma/Django demos,
  which issue a second query for the nested parent. That is an ORM capability difference, not a
  language one.
- **`AsNoTracking()`** is set, matching the read-only intent of the endpoint (Hibernate uses a
  read-only transaction; Prisma and Django do not track either).
- **`AddDbContextPool`** pools DbContext instances, and `Microsoft.Data.Sqlite` pools connections by
  default — comparable to Hikari in the Spring demo and the SeaORM pool in the Rust demo.
- **Logging is pinned to Warning.** ASP.NET Core logs every request at Information by default, which
  would charge this row for work no other demo does.
