#

```sh
pip install -r requirements.txt
python manage.py collectstatic --noinput
gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 4

gunicorn --workers 3 --bind unix:/run/mysite.sock mysite.wsgi:application

```

```sh
ab -n 10000 -c 10000 http://127.0.0.1:8000/contents/?format=json&page_size=20
```

## Configuration

Environment variables read by `mysite/settings.py`:

- `PGHOST` / `PGPORT` / `PGUSER` / `PGPASSWORD` / `PGDATABASE` (defaults `127.0.0.1` / `5432` /
  `bench` / `bench` / `demo`): the PostgreSQL database (driver: psycopg 3). `run.sh` and the
  Dockerfile also export `DATABASE_URL` and `DB_POOL_SIZE` for the harness; Django reads the PG*
  form. The tables are unmanaged and already loaded (`db/generate.sql`), so never run `migrate`.
- Connections: `CONN_MAX_AGE = None`, i.e. one persistent connection per gunicorn sync worker
  (4 workers, 4 connections) and no pool, since a sync worker serves one request at a time.
- `DJANGO_DEBUG` (default `false`)
- `DJANGO_ALLOWED_HOSTS`, comma-separated (default `localhost,127.0.0.1,[::1]`)
- `DJANGO_SECRET_KEY` (default: an insecure demo key)
- `DJANGO_LOG_LEVEL` (default `WARNING`; 4xx request logs are suppressed)

Invalid `page`/`page_size` values (not an integer, below 1, `page_size` above 100) return
400, e.g. `{"page_size": ["Ensure this value is less than or equal to 100."]}`. Every 404 is
`{"detail": "Not found."}`. `content` on update is required, non-blank and at most 1000 characters.

## Tests

Endpoint tests live in `core/tests.py` (DRF `APITestCase`, Django test runner). Run them from
the repo root, each demo in its own container:

```sh
./test.sh python
```

This builds the `test` stage of `demo-python/Dockerfile` and runs `python manage.py test` as the
container's command, so the exit code is the result. test.sh clones a fresh `test_python` database
from `demo_template` and passes it in as `DATABASE_URL` plus the PG* variables. A plain
`docker build -f demo-python/Dockerfile .` still builds only the runtime image, which holds no data.

Django's default runner would create its own empty `test_<NAME>` database and run the contrib
migrations into it. Instead, `TEST_RUNNER` points at `core/test_runner.py`, which skips test
database setup and teardown and runs against the given database as-is. That is the cleanest fit
here: the models are unmanaged, the dataset is already in the database test.sh hands over, and
nothing needs creating, copying or migrating. (The alternative, `TEST: {'TEMPLATE': 'demo_template'}`,
would hard-code the template name and ignore the database the harness provides.) `APITestCase`
still wraps each test in a transaction that is rolled back, and `test_update_content` also
restores content 2 explicitly. The 16 cases are the same in every demo of the repo (contents list,
item at each category level, update, categories); each one writes the full expected JSON inline
and pins current behaviour.
