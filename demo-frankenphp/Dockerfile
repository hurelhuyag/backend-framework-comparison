# Build context is the REPO ROOT: docker build -f demo-frankenphp/Dockerfile .
#
# The SAME Laravel application as demo-php, served by FrankenPHP in worker mode through
# Laravel Octane: each worker boots Laravel once and keeps it in memory between requests,
# instead of php-fpm's boot-per-request. The two PHP rows differ only in the server.
# demo-php's tests cover the application; this image adds no tests of its own.

# Vendor is installed under php 8.4, the version that runs it (see demo-php/Dockerfile).
FROM php:8.4-cli-bookworm AS vendor
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY demo-php/composer.json demo-php/composer.lock ./
RUN composer install --no-interaction --no-dev --no-scripts --no-autoloader --prefer-dist
COPY demo-php/ ./
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative --no-scripts

FROM dunglas/frankenphp:1-php8.4-bookworm
# Same opcache + JIT settings as the php-fpm image, so the PHP rows compare servers, not tuning.
# pcntl: Octane's start command handles SIGINT/SIGTERM itself.
RUN install-php-extensions pdo_pgsql opcache pcntl && php -m | grep -qi '^pdo_pgsql$' && php -m | grep -qi '^pcntl$'
COPY demo-php/docker/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

WORKDIR /app/demo-frankenphp
COPY --from=vendor /src ./
COPY demo-frankenphp/run.sh ./run.sh

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    OCTANE_SERVER=frankenphp \
    DB_CONNECTION=pgsql \
    DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 \
    PGPORT=5432 \
    PGUSER=bench \
    PGPASSWORD=bench \
    PGDATABASE=demo \
    DB_POOL_SIZE=32 \
    PORT=8004

RUN mkdir -p bootstrap/cache \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
    && cp .env.example .env \
    && php artisan key:generate --force \
    && php artisan package:discover --ansi
# No config:cache here: it would freeze the PG* defaults above. run.sh start caches the config
# from the container's actual environment.

EXPOSE 8004
CMD ["./run.sh", "start"]
