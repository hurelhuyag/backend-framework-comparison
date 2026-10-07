```

ab -n 10000 -c 1 http://localhost:8001/api/contents
```

## Tests

Endpoint tests live in `tests/Feature/EndpointsTest.php` (PHPUnit feature tests). They run in their
own container: the `test` stage of the `Dockerfile` installs the dev dependencies and `pdo_pgsql`,
copies the app and the tests, and runs `vendor/bin/phpunit` against the PostgreSQL database named by
the `PG*` variables (`test.sh` passes a fresh `test_php` clone of `demo_template`). The one write
(`PUT /api/contents/2`) is restored after each test. From the repo root:

```
./test.sh php
```

A plain `docker build -f demo-php/Dockerfile .` never builds the `test` stage, so the production
image stays `--no-dev`.

## Database

PostgreSQL via Laravel's `pgsql` connection. `config/database.php` reads `DB_*` if set, else the
libpq `PGHOST`/`PGPORT`/`PGDATABASE`/`PGUSER`/`PGPASSWORD` (defaults `127.0.0.1`/`5432`/`demo`/
`bench`/`bench`). PHP-FPM runs 32 static workers, each holding one persistent PDO connection
(`PDO::ATTR_PERSISTENT`), so there is no pool. The image does not contain the dataset; `run.sh start`
builds Laravel's config cache at container start so it reflects the `PG*` the container got.

## FrankenPHP

`laravel/octane` is a dependency so that `../demo-frankenphp` can serve this same application in
FrankenPHP worker mode. Under Nginx + PHP-FPM it is unused apart from its service provider, which
package discovery registers.
