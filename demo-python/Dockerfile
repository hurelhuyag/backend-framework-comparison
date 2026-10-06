# Build context is the REPO ROOT: docker build -f demo-python/Dockerfile .
# Stages: app (shared base) -> test (only built with --target test) -> final runtime image.
FROM python:3.13-slim-bookworm AS app
WORKDIR /app/demo-python
COPY demo-python/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn
COPY demo-python/ ./
COPY demo.sqlite /app/demo.sqlite
# settings.py resolves the db as DEMO_DB, defaulting to BASE_DIR/demo.sqlite
RUN ln -sf /app/demo.sqlite /app/demo-python/demo.sqlite
# run.sh looks for $VENV/bin/gunicorn; pip installed it under /usr/local
ENV VENV=/usr/local
ENV PORT=8000
ENV PYTHONDONTWRITEBYTECODE=1

# Endpoint tests against this image's own copy of demo.sqlite: ./test.sh python
# (or docker build --target test, then docker run). Exit code is the test result.
FROM app AS test
ENV DEMO_DB=/app/demo.sqlite
CMD ["python", "manage.py", "test", "-v", "2"]

FROM app AS runtime
EXPOSE 8000
CMD ["./run.sh", "start"]
