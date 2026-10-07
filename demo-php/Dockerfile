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

# Test stage: `docker build -f demo-php/Dockerfile --target test .` then `docker run --rm <image>`.
# A plain build never reaches it (the final stage does not depend on it). Dev dependencies are
# installed here, inside the build. The tests connect to whatever database the PG* variables name
# (test.sh hands them a fresh clone of demo_template) and restore the one row they write.
FROM php:8.4-cli-bookworm AS test
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip libpq-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*
RUN php -m | grep -qi '^pdo_pgsql$'
WORKDIR /repo/demo-php
COPY demo-php/composer.json demo-php/composer.lock ./
RUN composer install --no-interaction --no-scripts --no-autoloader --prefer-dist
COPY demo-php/ ./
RUN composer dump-autoload --no-scripts
CMD ["vendor/bin/phpunit", "--colors=never", "--testdox"]

FROM php:8.4-fpm-bookworm
# pdo_pgsql is compiled against libpq-dev, which is purged again; only the libpq5 runtime library
# stays. Assert the driver is present so a missing one fails the build instead of the benchmark.
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx libpq5 libpq-dev \
    && docker-php-ext-install -j"$(nproc)" opcache pdo_pgsql \
    && apt-mark manual libpq5 \
    && apt-get purge -y --auto-remove libpq-dev \
    && rm -rf /var/lib/apt/lists/*
RUN php -m | grep -qi '^pdo_pgsql$'

COPY demo-php/docker/nginx.conf /etc/nginx/nginx.conf
COPY demo-php/docker/zz-pool.conf /usr/local/etc/php-fpm.d/zz-pool.conf
COPY demo-php/docker/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

WORKDIR /app/demo-php
COPY --from=vendor /src ./

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    DB_CONNECTION=pgsql \
    DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 \
    PGPORT=5432 \
    PGUSER=bench \
    PGPASSWORD=bench \
    PGDATABASE=demo \
    DB_POOL_SIZE=32 \
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
    && php artisan package:discover --ansi
# No config:cache here: it would freeze the PG* defaults above. run.sh start caches the config
# from the container's actual environment.

EXPOSE 8001
CMD ["./run.sh", "start"]
