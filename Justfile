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
           seed-laravel/vendor seed-laravel/node_modules \
           logs/app/* logs/nginx/* logs/php/* logs/postgres/* logs/mail/* logs/python/*
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

# ── Check ─────────────────────────────────────────────────────────────────────

# Smoke-test all features: HTTP endpoints, auth, private API, email, DB tables, tools
check:
    #!/usr/bin/env bash
    BASE="http://localhost:${HTTP_PORT:-80}"
    PASS=0; FAILURES=0

    ok()   { echo "  ✓  $1"; PASS=$((PASS+1)); }
    fail() { echo "  ✗  $1"; FAILURES=$((FAILURES+1)); }

    http_check() {
        local label="$1" url="$2" want="${3:-200}"
        local got
        got=$(curl -s -o /dev/null -w "%{http_code}" "$url")
        [ "$got" = "$want" ] && ok "$label" || fail "$label — expected HTTP $want, got $got"
    }

    echo ""
    echo "── HTTP endpoints ───────────────────────────────────────────────────"
    http_check "Landing page     GET /"              "$BASE/"
    http_check "Login page       GET /login"         "$BASE/login"
    http_check "SPA              GET /spa/"           "$BASE/spa/"
    http_check "Health           GET /up"             "$BASE/up"
    http_check "Public API       GET /api/v1/status"  "$BASE/api/v1/status"
    http_check "Public API       GET /api/v1/ping"    "$BASE/api/v1/ping"

    echo ""
    echo "── Sanctum bearer token ─────────────────────────────────────────────"
    RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE/api/v1/auth/token" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${DEMO_USER_EMAIL:-admin@seed.local}\",\"password\":\"${DEMO_USER_PASSWORD:-password}\"}")
    CODE=$(echo "$RESP" | tail -1)
    BODY=$(echo "$RESP" | sed '$d')
    TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        ok "Token issued     POST /api/v1/auth/token → HTTP $CODE"
        CODE2=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE/api/v1/me")
        [ "$CODE2" = "200" ] \
            && ok "Private API      GET /api/v1/me (Bearer token)" \
            || fail "Private API      GET /api/v1/me — HTTP $CODE2"
    else
        fail "Token issue      POST /api/v1/auth/token — HTTP $CODE"
        fail "Private API      skipped (no token)"
    fi

    echo ""
    echo "── Email (Mailpit) ──────────────────────────────────────────────────"
    BEFORE=$(curl -s "http://localhost:${MAILPIT_WEB_PORT:-8025}/api/v1/messages" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo 0)
    SEND=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/mail/send?to=check@seed.local")
    AFTER=$(curl -s "http://localhost:${MAILPIT_WEB_PORT:-8025}/api/v1/messages" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo 0)
    [ "$SEND" = "200" ] \
        && ok "Email sent       GET /mail/send" \
        || fail "Email send       GET /mail/send — HTTP $SEND"
    [ "$AFTER" -gt "$BEFORE" ] 2>/dev/null \
        && ok "Mailpit captured the message ($AFTER total in inbox)" \
        || fail "Mailpit inbox    message count did not increase"

    echo ""
    echo "── Database (PostgreSQL) ────────────────────────────────────────────"
    for table in users sessions personal_access_tokens migrations; do
        COUNT=$(docker exec seed-postgres psql -U "$DB_USERNAME" -d "$DB_DATABASE" \
            -tAc "SELECT COUNT(*) FROM $table" 2>/dev/null)
        [ -n "$COUNT" ] \
            && ok "Table '$table' ($COUNT rows)" \
            || fail "Table '$table' not found"
    done

    echo ""
    echo "── Python · HTTP endpoints ──────────────────────────────────────────"
    http_check "Landing page     GET /py/"                   "$BASE/py/"
    http_check "Login page       GET /py/login/"             "$BASE/py/login/"
    http_check "Public API       GET /py/api/v1/status"      "$BASE/py/api/v1/status"
    http_check "Public API       GET /py/api/v1/ping"        "$BASE/py/api/v1/ping"
    http_check "API Docs         GET /py/api/v1/docs"        "$BASE/py/api/v1/docs"

    echo ""
    echo "── Python · Bearer token ────────────────────────────────────────────"
    PY_RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE/py/api/v1/auth/token" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${DEMO_USER_EMAIL:-admin@seed.local}\",\"password\":\"${DEMO_USER_PASSWORD:-password}\"}")
    PY_CODE=$(echo "$PY_RESP" | tail -1)
    PY_BODY=$(echo "$PY_RESP" | sed '$d')
    PY_TOKEN=$(echo "$PY_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
    if [ -n "$PY_TOKEN" ]; then
        ok "Token issued     POST /py/api/v1/auth/token → HTTP $PY_CODE"
        PY_CODE2=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $PY_TOKEN" "$BASE/py/api/v1/me")
        [ "$PY_CODE2" = "200" ] \
            && ok "Private API      GET /py/api/v1/me (Bearer token)" \
            || fail "Private API      GET /py/api/v1/me — HTTP $PY_CODE2"
    else
        fail "Token issue      POST /py/api/v1/auth/token — HTTP $PY_CODE"
        fail "Private API      skipped (no token)"
    fi

    echo ""
    echo "── Python · Database (PostgreSQL) ───────────────────────────────────"
    for table in auth_user tokens_apitoken django_migrations django_session; do
        COUNT=$(docker exec seed-postgres psql -U "$DB_USERNAME" -d "$DB_DATABASE" \
            -tAc "SELECT COUNT(*) FROM $table" 2>/dev/null)
        [ -n "$COUNT" ] \
            && ok "Table '$table' ($COUNT rows)" \
            || fail "Table '$table' not found"
    done

    echo ""
    echo "── Dev tools ────────────────────────────────────────────────────────"
    http_check "Mailpit UI       http://localhost:${MAILPIT_WEB_PORT:-8025}" \
        "http://localhost:${MAILPIT_WEB_PORT:-8025}/"
    http_check "Adminer          http://localhost:${ADMINER_PORT:-8081}" \
        "http://localhost:${ADMINER_PORT:-8081}/"

    echo ""
    TOTAL=$((PASS + FAILURES))
    if [ "$FAILURES" = "0" ]; then
        echo "  All $TOTAL checks passed."
    else
        echo "  $PASS / $TOTAL passed  —  $FAILURES failed."
    fi
    echo ""

# ── Python (Django + FastAPI) ─────────────────────────────────────────────────

# Open bash shell inside Python container
py-shell:
    docker exec -it seed-python bash

# Run a Django management command: just py-manage migrate
py-manage *args:
    docker exec -it seed-python python manage.py {{args}}

# Follow Python container logs
logs-python:
    docker compose logs -f python

# Tail Python application log (readable offline from logs/python/)
logs-seed-django:
    tail -f logs/python/app.log

# Rebuild Python image then start
py-rebuild:
    docker compose up -d --build python

# ── Info ──────────────────────────────────────────────────────────────────────

# Print all service URLs
info:
    @echo ""
    @echo "  ── PHP / Laravel ──────────────────────────────────────────────"
    @echo "  App (HTTP):     http://localhost:${HTTP_PORT}"
    @echo "  Login:          http://localhost:${HTTP_PORT}/login"
    @echo "  Public API:     http://localhost:${HTTP_PORT}/api/v1/status"
    @echo "  Private API:    http://localhost:${HTTP_PORT}/api/v1/me  (Bearer token)"
    @echo "  SPA:            http://localhost:${HTTP_PORT}/spa/"
    @echo ""
    @echo "  ── Python / Django + FastAPI ───────────────────────────────────"
    @echo "  Home:           http://localhost:${HTTP_PORT}/py/"
    @echo "  Login:          http://localhost:${HTTP_PORT}/py/login/"
    @echo "  Dashboard:      http://localhost:${HTTP_PORT}/py/dashboard/"
    @echo "  Contact form:   http://localhost:${HTTP_PORT}/py/contact/"
    @echo "  Public API:     http://localhost:${HTTP_PORT}/py/api/v1/status"
    @echo "  Private API:    http://localhost:${HTTP_PORT}/py/api/v1/me  (Bearer token)"
    @echo "  API Docs:       http://localhost:${HTTP_PORT}/py/api/v1/docs"
    @echo ""
    @echo "  ── Shared services ────────────────────────────────────────────"
    @echo "  Mailpit:        http://localhost:${MAILPIT_WEB_PORT}"
    @echo "  Adminer:        http://localhost:${ADMINER_PORT}"
    @echo "  PostgreSQL:     localhost:${POSTGRES_PORT}  db=${DB_DATABASE}  user=${DB_USERNAME}"
    @echo ""
