# demo-dotnet — C# / ASP.NET Core / EF Core / PostgreSQL

Seventh entry in the comparison: **ASP.NET Core 10 Minimal APIs** + **EF Core 10** (Npgsql provider) against the same
PostgreSQL dataset as every other demo (`demo_template`, built by `db/generate.sql`).

EF Core is used rather than Dapper or raw `Npgsql`, for the same reason the Rust demo
uses SeaORM instead of raw `sqlx`: every other demo here goes through a full ORM (Hibernate, GORM,
Prisma, Eloquent, Django ORM, SeaORM), so hand-written SQL would measure a different workload.

## Run it in the benchmark harness

```sh
./run.sh --only dotnet            # from the repo root
```

The `Dockerfile` builds with the **repo root as context** (the image does not contain the dataset):

```sh
docker build -f demo-dotnet/Dockerfile -t bfc-dotnet:bench .
```

## Build & run natively

```sh
cd demo-dotnet
dotnet publish -c Release -o ./publish
DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo ASPNETCORE_URLS=http://0.0.0.0:8082 ./publish/demo-dotnet
```

Overridable via env: `DATABASE_URL` (default `postgres://bench:bench@127.0.0.1:5432/demo`; when unset,
`PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE` are used, defaults `127.0.0.1`/`5432`/`bench`/`bench`/`demo`),
`DB_POOL_SIZE` (default `32`), `PORT` (default `8082`). The connection string is built in
`Data/DatabaseSettings.cs`.

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
- **`AddDbContextPool`** pools DbContext instances, and Npgsql pools connections with
  `Maximum Pool Size = DB_POOL_SIZE` (32) — the same budget as Hikari in the Spring demo and the
  SeaORM pool in the Rust demo. Other pool knobs stay at Npgsql defaults. `GSS Encryption Mode=Disable`
  stops Npgsql 10 probing for a Kerberos library the image does not have.
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
The tests connect to the database given by `DATABASE_URL` / `PG*`; test.sh hands them `test_dotnet`, a
fresh clone of `demo_template`. The only write (the `UpdateContent` case on content 2) is restored before
every test and when the run ends. The container's exit code is the test result.

With a local .NET 10 SDK: `db/postgres.sh reset dev_dotnet`, then
`cd demo-dotnet/tests && DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/dev_dotnet dotnet test`.
