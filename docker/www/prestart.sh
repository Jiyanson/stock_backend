#!/usr/bin/env bash

set -e

echo "FastAPI Prestart Script Running"

# Wait for PostgreSQL if in development
if [ "$IS_DEV" = "true" ]; then
  DB_HOST=$(python -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').hostname)")
  echo "Waiting for postgres to be available at host '${DB_HOST}'"
  
  for i in {1..120}; do
    if nc -z "${DB_HOST}" 5432; then
      echo "Postgres is up!"
      break
    fi
    echo "$DATABASE_URL"
    echo "Still waiting for postgres..."
    sleep 1
  done

  if ! nc -z "${DB_HOST}" 5432; then
    echo "ERROR: Could not connect to Postgres after 30 seconds."
    exit 1
  fi
fi

echo "Run Database Migrations"
echo "Listing /app:"
ls -l /app
echo "Listing /app/db:"
ls -l /app/db
echo "Showing /app/alembic.ini:"
cat /app/alembic.ini
python -m alembic -c /app/alembic.ini upgrade head


if [ "$CREATE_TEST_DATA" = "true" ]; then
  echo "Creating test data..."
  python -m stock_backend.cli test-data
fi

chmod -R 755 /app/db 2>/dev/null || true

echo "Starting FastAPI (Uvicorn)..."
exec uvicorn stock_backend.www:app --host 0.0.0.0 --port 80 --reload --reload-dir /app/stock_backend
