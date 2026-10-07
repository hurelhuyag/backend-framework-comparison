# demo-frankenphp: FrankenPHP + Laravel Octane (PostgreSQL)

The **same Laravel application as `../demo-php`**, served by [FrankenPHP](https://frankenphp.dev/)
in worker mode through [Laravel Octane](https://laravel.com/docs/octane). This directory holds no
PHP code of its own, only how the app is served, so the two PHP rows in the benchmark differ only
in the server:

| | `demo-php` | `demo-frankenphp` |
|---|---|---|
| Server | Nginx + PHP-FPM (32 static workers) | FrankenPHP 1.x (Caddy), Octane workers |
| Laravel boot | on every request | once per worker, kept in memory |
| PHP | 8.4, opcache + tracing JIT | 8.4 ZTS, same opcache.ini |
| DB connections | one persistent PDO connection per fpm worker | one per Octane worker, kept between requests |

Octane runs with its defaults: `--workers=auto` (FrankenPHP starts 2 workers per CPU, so 8 in the
4-core container) and `--max-requests=500` (each worker restarts after 500 requests). Override
with `WORKERS` and `MAX_REQUESTS`.

## Run

Docker (build context is the repo root; needs the PostgreSQL server from `../db/postgres.sh start`):

```sh
docker build -f demo-frankenphp/Dockerfile -t bfc-frankenphp .
docker run --rm --network host bfc-frankenphp      # http://localhost:8004/api/contents?page_size=20
```

The image builds `../demo-php`'s vendor under PHP 8.4, adds `pdo_pgsql`, `opcache` and `pcntl`
(Octane's start command handles SIGINT/SIGTERM itself) to the official `dunglas/frankenphp`
image, and caches the Laravel config at container start from the `PG*` variables it is given.

## Tests

The application's 16 endpoint tests live in `../demo-php` (`./test.sh php`). Because worker mode
keeps state between requests, the same endpoints were also compared byte for byte against the
php-fpm image, before and after 2000 requests (several worker restarts at `max-requests=500`).
