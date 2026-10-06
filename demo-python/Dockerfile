# Build context is the REPO ROOT: docker build -f demo-python/Dockerfile .
FROM python:3.13-slim-bookworm
WORKDIR /app/demo-python
COPY demo-python/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn
COPY demo-python/ ./
COPY demo.sqlite /app/demo.sqlite
# settings.py resolves the db as BASE_DIR/demo.sqlite
RUN ln -sf /app/demo.sqlite /app/demo-python/demo.sqlite
# run.sh looks for $VENV/bin/gunicorn; pip installed it under /usr/local
ENV VENV=/usr/local
ENV PORT=8000
EXPOSE 8000
CMD ["./run.sh", "start"]
