# Build context is the REPO ROOT: docker build -f demo-php/Dockerfile .
# Serves Laravel through Nginx + PHP-FPM, matching the stack in the root README
# (NOT `php artisan serve`, which is single-threaded and not comparable).
# Vendor is installed under the SAME php 8.4 that runs it. The composer:2 image ships php 8.5,
# which composer.lock rejects (nette/schema caps at php 8.4).
FROM php:8.4-cli-bookworm AS vendor
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY demo-php/composer.json demo-php/composer.lock ./
RUN composer install --no-interaction --no-dev --no-scripts --no-autoloader --prefer-dist
COPY demo-php/ ./
# --no-scripts: Laravel's post-autoload-dump hook runs `artisan package:discover`, which needs a
# .env and a PHP runtime that this stage does not have. It is run in the final image instead.
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative --no-scripts

FROM php:8.4-fpm-bookworm
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx libsqlite3-dev \
    && docker-php-ext-install -j"$(nproc)" opcache \
    && rm -rf /var/lib/apt/lists/*

# pdo_sqlite ships enabled in the official php images; build it only if that ever changes,
# then assert it is present so a missing driver fails the build instead of the benchmark.
RUN php -m | grep -qi '^pdo_sqlite$' || docker-php-ext-install -j"$(nproc)" pdo_sqlite
RUN php -m | grep -qi '^pdo_sqlite$'

COPY demo-php/docker/nginx.conf /etc/nginx/nginx.conf
COPY demo-php/docker/zz-pool.conf /usr/local/etc/php-fpm.d/zz-pool.conf
COPY demo-php/docker/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

WORKDIR /app/demo-php
COPY --from=vendor /src ./
COPY demo.sqlite /app/demo.sqlite
# php-fpm runs as www-data, and SQLite in WAL mode creates -wal/-shm beside the database,
# so that user needs write access to the file AND its directory - otherwise even a plain
# SELECT fails with "attempt to write a readonly database".
RUN chown www-data:www-data /app /app/demo.sqlite

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    DB_CONNECTION=sqlite \
    DB_DATABASE=/app/demo.sqlite \
    PHP_SERVER=fpm \
    PORT=8001

# bootstrap/cache is gitignored and absent from the repo, and artisan needs it writable
# BEFORE package:discover runs. /bin/sh has no brace expansion, so spell the paths out.
RUN mkdir -p bootstrap/cache \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && cp .env.example .env \
    && php artisan key:generate --force \
    && php artisan package:discover --ansi \
    && php artisan config:cache

EXPOSE 8001
CMD ["./run.sh", "start"]
