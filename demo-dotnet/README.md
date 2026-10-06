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
| GET | `/categories` | all 100 rows, each with its full parent chain |

Defaults match the Django/NextJS demos: page 1, size 20, capped at 100. Ordered by `id ASC`, and no
`COUNT(*)` is issued.

## Notes for a fair reading of the numbers

- **One query per request.** Every nested category carries its parent chain up to the root. The
  category tree is 3 levels deep, so `Include(...).ThenInclude(...).ThenInclude(...)` resolves
  `content -> category -> parent -> grandparent` in a single SQL statement with three `LEFT JOIN`s
  (`/categories`: one statement, two `LEFT JOIN`s), because EF Core aliases the self-referencing joins.
  This matches Hibernate's `@NamedEntityGraph` and is *better* than demos that issue extra queries
  for the nested parents. That is an ORM capability difference, not a
  language one.
- **`AsNoTracking()`** is set, matching the read-only intent of the endpoint (Hibernate uses a
  read-only transaction; Prisma and Django do not track either).
- **`AddDbContextPool`** pools DbContext instances, and `Microsoft.Data.Sqlite` pools connections by
  default — comparable to Hikari in the Spring demo and the SeaORM pool in the Rust demo.
- **Logging is pinned to Warning.** ASP.NET Core logs every request at Information by default, which
  would charge this row for work no other demo does.

## Tests

`tests/` is a separate xUnit project (excluded from the main build) that boots the app in-process with
`WebApplicationFactory<Program>`. It holds the same 16 endpoint cases as every other demo, each with its
full expected JSON inline.

Run them from the repo root:

```sh
./test.sh dotnet
```

This builds the `test` stage of the `Dockerfile` (`--target test`; a plain build skips it) and runs it.
The stage copies `demo.sqlite` (built by `db/generate.sql`) into the image, and before every test the
factory copies it again to a temp file that `DEMO_DB` points to, so no run touches the repo's database
or shares one with another demo. The container's exit code is the test result.

With a local .NET 10 SDK: `cd demo-dotnet/tests && dotnet test` (uses the repo-root `demo.sqlite` the same way).
