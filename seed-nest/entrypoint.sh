#!/bin/bash
set -e

echo "[nest] Installing dependencies..."
npm install --prefer-offline --silent
echo "[nest] Rebuilding native addons for container OS..."
npm rebuild --silent

echo "[nest] Waiting for PostgreSQL..."
until (echo > /dev/tcp/${DB_HOST:-postgres}/${DB_PORT:-5432}) 2>/dev/null; do
  sleep 1
done
echo "[nest] PostgreSQL is ready."

echo "[nest] Building TypeScript..."
npm run build

echo "[nest] Bootstrap complete — starting NestJS on :3000"
exec node dist/main.js
