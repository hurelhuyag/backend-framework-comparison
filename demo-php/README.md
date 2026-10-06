```

ab -n 10000 -c 1 http://localhost:8001/api/contents
```

## Tests

Endpoint tests live in `tests/Feature/EndpointsTest.php` (PHPUnit feature tests). They run in their
own container: the `test` stage of the `Dockerfile` installs the dev dependencies, copies the app,
the tests and the prepared repo-root `demo.sqlite` into the image (`/repo/demo.sqlite`), and runs
`vendor/bin/phpunit`. Each test copies that file to a temp file first, so nothing is shared with the
repo or with other demos. From the repo root:

```
./test.sh php
```

A plain `docker build -f demo-php/Dockerfile .` never builds the `test` stage, so the production
image stays `--no-dev`.
