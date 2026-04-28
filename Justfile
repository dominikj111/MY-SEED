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
