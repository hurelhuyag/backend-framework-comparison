#

```sh
pip install -r requirements.txt
python manage.py collectstatic --noinput
python manage.py migrate
gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 4

gunicorn --workers 3 --bind unix:/run/mysite.sock mysite.wsgi:application

```

```sh
ab -n 10000 -c 10000 http://127.0.0.1:8000/contents/?format=json&page_size=20
```

## Configuration

Environment variables read by `mysite/settings.py`:

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

This builds the `test` stage of `demo-python/Dockerfile` (which copies `demo.sqlite` into the
image and sets `DEMO_DB=/app/demo.sqlite`) and runs `python manage.py test` as the container's
command, so the exit code is the result. A plain `docker build -f demo-python/Dockerfile .` still
builds only the runtime image. Nothing is mounted from the host: the tests read the image's own
copy of `demo.sqlite`, never the repo file.

Django's runner uses its own in-memory test database, so `setUpTestData` copies the schema and
all rows from a read-only connection to `DEMO_DB` into it. The 16 cases are the same in every
demo of the repo (contents list, item at each category level, update, categories); each one
writes the full expected JSON inline and pins current behaviour.
