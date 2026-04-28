# the-seed — run `just` to list all recipes
# Requires: just (brew install just), Docker Desktop
# Optional: mkcert (brew install mkcert && mkcert -install) for HTTPS

set dotenv-load := true   # reads .env — same file Docker Compose and Laravel use

# List all available recipes
default:
    @just --list

# ── Lifecycle ─────────────────────────────────────────────────────────────────

# Start all containers (first run auto-creates Laravel, migrates DB, seeds demo data)
up:
    #!/usr/bin/env bash
    set -e
    [ ! -f .env ]              && cp .env.example .env              && echo "Created .env from .env.example"
    [ ! -f configs/msmtprc ]   && cp configs/msmtprc.example configs/msmtprc && echo "Created configs/msmtprc from example"
    chmod +x docker/entrypoint.sh
    docker compose up -d

# Rebuild PHP image then start (required when Dockerfile changes)
rebuild:
    #!/usr/bin/env bash
    set -e
    [ ! -f .env ]              && cp .env.example .env              && echo "Created .env from .env.example"
    [ ! -f configs/msmtprc ]   && cp configs/msmtprc.example configs/msmtprc && echo "Created configs/msmtprc from example"
    chmod +x docker/entrypoint.sh
    docker compose up -d --build

# Full reset: drop DB, wipe generated app files, rebuild from scratch
fresh:
    #!/usr/bin/env bash
    set -e
    [ ! -f .env ]              && cp .env.example .env              && echo "Created .env from .env.example"
    [ ! -f configs/msmtprc ]   && cp configs/msmtprc.example configs/msmtprc && echo "Created configs/msmtprc from example"
    docker compose down -v
    rm -rf database/data/* \
           app/vendor app/node_modules \
           logs/app/* logs/nginx/* logs/php/* logs/postgres/* logs/mail/*
    chmod +x docker/entrypoint.sh
    docker compose up -d --build

# Stop all containers
stop:
    docker compose down

# Restart a single service: just restart nginx
restart service="php":
    docker compose restart {{service}}

# ── SSL ───────────────────────────────────────────────────────────────────────

# Generate locally-trusted HTTPS certs via mkcert (run once after installing mkcert)
# After running: ensure APP_DOMAIN is in /etc/hosts, then `just restart nginx`
ssl:
    #!/usr/bin/env bash
    set -e
    if ! command -v mkcert &>/dev/null; then
        echo "mkcert not found."
        echo "Install: brew install mkcert && mkcert -install"
        exit 1
    fi
    mkdir -p docker/certs
    mkcert \
        -cert-file docker/certs/seed.pem \
        -key-file  docker/certs/seed-key.pem \
        "${APP_DOMAIN}" localhost 127.0.0.1
    echo ""
    echo "Certs written to docker/certs/"
    echo "Add to /etc/hosts:  127.0.0.1  ${APP_DOMAIN}"
    echo "Then run: just restart nginx"

# ── Logs ─────────────────────────────────────────────────────────────────────

# Follow PHP container stdout (entrypoint bootstrap + php-fpm)
logs:
    docker compose logs -f php

# Tail nginx access + error logs (readable offline from logs/nginx/)
logs-nginx:
    tail -f logs/nginx/access.log logs/nginx/error.log

# Tail Laravel application log (readable offline from logs/app/)
logs-app:
    tail -f logs/app/laravel.log

# Tail PostgreSQL log (readable offline from logs/postgres/)
logs-db:
    tail -f logs/postgres/postgresql.log

# Tail mail log
logs-mail:
    tail -f logs/mail/msmtp.log

# ── Development ───────────────────────────────────────────────────────────────

# Open bash shell inside PHP container (composer, artisan, npm all available)
shell:
    docker exec -it seed-php bash

# Run Artisan command: just artisan migrate:status
artisan *args:
    docker exec -it seed-php php artisan {{args}}

# Run Composer inside container: just composer require vendor/package
composer *args:
    docker exec -it seed-php composer --working-dir=/app {{args}}

# Run npm inside container: just npm run build
npm *args:
    docker exec -it seed-php npm --prefix /app {{args}}

# ── Database ──────────────────────────────────────────────────────────────────

# Open PostgreSQL interactive shell
db:
    docker exec -it seed-postgres psql -U $DB_USERNAME -d $DB_DATABASE

# Dump database to backup.sql
db-backup:
    docker exec seed-postgres pg_dump -U $DB_USERNAME $DB_DATABASE > backup.sql
    @echo "Saved to backup.sql"

# Restore database from backup.sql
db-restore:
    docker exec -i seed-postgres psql -U $DB_USERNAME -d $DB_DATABASE < backup.sql

# ── Info ──────────────────────────────────────────────────────────────────────

# Print all service URLs
info:
    @echo ""
    @echo "  App (HTTPS):    https://${APP_DOMAIN}"
    @echo "  App (HTTP):     http://localhost:${HTTP_PORT}"
    @echo "  Login:          https://${APP_DOMAIN}/login"
    @echo "  Public API:     https://${APP_DOMAIN}/api/v1/status"
    @echo "  Private API:    https://${APP_DOMAIN}/api/v1/me  (Bearer token)"
    @echo "  SPA:            https://${APP_DOMAIN}/spa/"
    @echo "  Mailpit:        http://localhost:${MAILPIT_WEB_PORT}"
    @echo "  Adminer:        http://localhost:${ADMINER_PORT}"
    @echo "  PostgreSQL:     localhost:${POSTGRES_PORT}  db=${DB_DATABASE}  user=${DB_USERNAME}"
    @echo ""
