#!/usr/bin/env bash

echo "Celery Prestart Script Running"
#!/bin/sh

# Fix permissions for mounted directory (if needed)
chmod -R 755 /app/db 2>/dev/null || true

# Start the FastAPI app with reloader
exec uvicorn stock_backend.www:app --host 0.0.0.0 --port 80 --reload --reload-dir /app/stock_backend
