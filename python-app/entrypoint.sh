#!/bin/bash
set -e

echo "[python] Waiting for PostgreSQL..."
until python -c "
import psycopg, os, sys
try:
    psycopg.connect(
        host=os.getenv('DB_HOST','postgres'),
        port=os.getenv('DB_PORT','5432'),
        dbname=os.getenv('DB_DATABASE','seeddb'),
        user=os.getenv('DB_USERNAME','seeduser'),
        password=os.getenv('DB_PASSWORD','secret'),
    ).close()
    sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null; do
    sleep 1
done
echo "[python] PostgreSQL is ready."

echo "[python] Running migrations..."
python manage.py migrate --noinput

echo "[python] Seeding demo data..."
python manage.py seed_demo

echo "[python] Bootstrap complete — starting uvicorn on :8000"
exec uvicorn config.asgi:application --host 0.0.0.0 --port 8000 --reload --log-level info
