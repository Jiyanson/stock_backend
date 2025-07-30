#!/usr/bin/env bash

set -e

echo "FastAPI Prestart Script Running"

# Wait for PostgreSQL if in development
if [ "$IS_DEV" = "true" ]; then
  DB_HOST=$(python -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').hostname)")
  echo "Waiting for postgres to be available at host '${DB_HOST}'"
  
  # Wait longer and add more debugging
  for i in {1..180}; do
    if nc -z "${DB_HOST}" 5432; then
      echo "Postgres is up!"
      break
    fi
    echo "DATABASE_URL: $DATABASE_URL"
    echo "Still waiting for postgres... (attempt $i/180)"
    sleep 2
  done

  if ! nc -z "${DB_HOST}" 5432; then
    echo "ERROR: Could not connect to Postgres after 6 minutes."
    exit 1
  fi

  # Additional wait to ensure Postgres is fully ready
  echo "Waiting additional 5 seconds for Postgres to be fully ready..."
  sleep 5
fi

echo "Run Database Migrations"
echo "Current directory: $(pwd)"
echo "Listing /app:"
ls -la /app

# Verify alembic.ini exists and is readable
if [ ! -f "/app/alembic.ini" ]; then
    echo "ERROR: alembic.ini not found!"
    exit 1
fi

echo "alembic.ini permissions:"
ls -la /app/alembic.ini

echo "Contents of alembic.ini:"
head -n 10 /app/alembic.ini

# Fix permissions just in case
chmod 644 /app/alembic.ini
chmod -R 755 /app/db

echo "Running Alembic migrations..."
python -m alembic -c /app/alembic.ini upgrade head

if [ "$CREATE_TEST_DATA" = "true" ]; then
  echo "Creating test data..."
  python -m stock_backend.cli test-data
fi

echo "Starting FastAPI (Uvicorn)..."
exec uvicorn stock_backend.www:app --host 0.0.0.0 --port 80 --reload --reload-dir /app/stock_backend