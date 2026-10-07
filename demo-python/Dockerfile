# Build context is the REPO ROOT: docker build -f demo-python/Dockerfile .
# Stages: app (shared base) -> test (only built with --target test) -> final runtime image.
# The image holds no data: it connects to PostgreSQL (bfc-postgres, see db/postgres.sh).
FROM python:3.13-slim-bookworm AS app
WORKDIR /app/demo-python
COPY demo-python/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn
COPY demo-python/ ./
# run.sh looks for $VENV/bin/gunicorn; pip installed it under /usr/local
ENV VENV=/usr/local
ENV PORT=8000
ENV PYTHONDONTWRITEBYTECODE=1
ENV DATABASE_URL=postgres://bench:bench@127.0.0.1:5432/demo \
    PGHOST=127.0.0.1 PGPORT=5432 PGUSER=bench PGPASSWORD=bench PGDATABASE=demo \
    DB_POOL_SIZE=32

# Endpoint tests against the database given by DATABASE_URL/PG*: ./test.sh python
# (or docker build --target test, then docker run --network host). Exit code is the test result.
FROM app AS test
CMD ["python", "manage.py", "test", "-v", "2"]

FROM app AS runtime
EXPOSE 8000
CMD ["./run.sh", "start"]
