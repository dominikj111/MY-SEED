#!/bin/bash
# Entrypoint — runs as root so it can fix permissions, then execs php-fpm.
# Bind-mounted from the host: edit without rebuilding the image.
set -e

echo "[seed] ── Starting container bootstrap ─────────────────────────────────"

# ── 0. SYMLINK ROOT .env → /app/.env ─────────────────────────────────────────
# The root .env is mounted at /project.env (not inside /app) to avoid virtiofs
# nested-mount conflicts on Docker Desktop for Mac.  A symlink makes it
# transparently available at /app/.env for Laravel and artisan.
# Always force-create so a stale 0-byte file from a previous failed mount
# attempt (Docker creates empty files at bind-mount targets) is replaced.
ln -sf /project.env /app/.env

# ── 1. CREATE LARAVEL PROJECT (first run only) ────────────────────────────────
# app/ already contains our custom files (controllers, views, routes, models).
# cp -n (no-clobber) means Laravel's defaults fill in everything else without
# overwriting the files we've already committed to app/.
if [ ! -f "/app/composer.json" ]; then
    echo "[seed] No Laravel project found — creating fresh installation..."
    rm -f /app/.gitkeep
    composer create-project laravel/laravel /tmp/laravel-new \
        --prefer-dist --no-interaction --quiet
    cp -rn /tmp/laravel-new/. /app/
    rm -rf /tmp/laravel-new
    echo "[seed] Laravel project created."
fi

# ── 2. VERIFY .env IS MOUNTED ─────────────────────────────────────────────────
if [ ! -e "/app/.env" ]; then
    echo "[seed] ERROR: /app/.env not found. Is /project.env mounted?"
    echo "[seed] Run: cp .env.example .env  then restart."
    exit 1
fi

# ── 3. INSTALL COMPOSER DEPENDENCIES ──────────────────────────────────────────
if [ ! -d "/app/vendor" ]; then
    echo "[seed] Installing Composer dependencies..."
    composer install \
        --working-dir=/app \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
        --quiet
fi

# Sanctum is not included in a default Laravel install — require it if absent.
# This runs once; subsequent container starts skip it (vendor/laravel/sanctum exists).
if [ ! -d "/app/vendor/laravel/sanctum" ]; then
    echo "[seed] Installing Laravel Sanctum..."
    composer require laravel/sanctum \
        --working-dir=/app \
        --no-interaction \
        --prefer-dist \
        --quiet
fi

# ── 4. WAIT FOR POSTGRESQL ────────────────────────────────────────────────────
echo "[seed] Waiting for PostgreSQL at ${DB_HOST:-postgres}:${DB_PORT:-5432}..."
MAX_TRIES=30
TRIES=0
until pg_isready \
    -h "${DB_HOST:-postgres}" \
    -p "${DB_PORT:-5432}" \
    -U "${DB_USERNAME:-seeduser}" \
    > /dev/null 2>&1
do
    TRIES=$((TRIES + 1))
    if [ "$TRIES" -ge "$MAX_TRIES" ]; then
        echo "[seed] ERROR: PostgreSQL not ready after ${MAX_TRIES} attempts. Exiting."
        exit 1
    fi
    echo "[seed] Waiting for PostgreSQL (${TRIES}/${MAX_TRIES})..."
    sleep 2
done
echo "[seed] PostgreSQL is ready."

# ── 5. APP KEY ────────────────────────────────────────────────────────────────
# Read the key directly from the file (not from the env var Docker injects).
# env_file: .env passes APP_KEY= (empty) into the container, so we must unset
# it for the subprocess or Laravel 11 refuses to write a new key.
APP_KEY_VALUE=$(grep "^APP_KEY=" /app/.env | cut -d'=' -f2)
if [ -z "$APP_KEY_VALUE" ]; then
    echo "[seed] Generating application key..."
    env -u APP_KEY php /app/artisan key:generate --force
fi

# ── 6. SANCTUM + SESSION TABLE + MIGRATE ─────────────────────────────────────

# Publish Sanctum config and migrations using tags (Sanctum 4.x / Laravel 11+
# no longer registers publishable resources without --tag).
if [ ! -f "/app/config/sanctum.php" ]; then
    echo "[seed] Publishing Sanctum config..."
    php /app/artisan vendor:publish --tag=sanctum-config --quiet || true
fi
if ! compgen -G "/app/database/migrations/*personal_access_tokens*" > /dev/null 2>&1; then
    echo "[seed] Publishing Sanctum migrations..."
    php /app/artisan vendor:publish --tag=sanctum-migrations --quiet || true
fi

# Create sessions migration if the file doesn't already exist.
if ! compgen -G "/app/database/migrations/*session*" > /dev/null 2>&1; then
    php /app/artisan session:table >/dev/null 2>&1 || true
fi

echo "[seed] Running migrations..."
php /app/artisan migrate --force --quiet

# ── 7. SEED ON FIRST RUN ──────────────────────────────────────────────────────
USER_COUNT=$(php /app/artisan tinker \
    --execute="echo App\Models\User::count();" 2>/dev/null \
    | grep -E '^[0-9]+$' | head -1 || echo "0")
if [ "${USER_COUNT:-0}" = "0" ]; then
    echo "[seed] First run — running database seeder..."
    php /app/artisan db:seed --force --quiet
    if [ -f /tmp/demo_api_token.txt ]; then
        echo "[seed] ──────────────────────────────────────────────────────────"
        echo "[seed] Demo API token (shown once — save it now):"
        echo "[seed]   $(cat /tmp/demo_api_token.txt)"
        echo "[seed] Usage:"
        echo "[seed]   curl -H 'Authorization: Bearer <token>' https://\${APP_DOMAIN}/api/v1/me"
        echo "[seed] Get a new token anytime:"
        echo "[seed]   POST /api/v1/auth/token  {email, password}"
        echo "[seed] ──────────────────────────────────────────────────────────"
        rm /tmp/demo_api_token.txt
    fi
fi

# ── 8. NPM INSTALL + ASSET BUILD ──────────────────────────────────────────────
if [ ! -d "/app/node_modules" ]; then
    echo "[seed] Installing Node dependencies..."
    cd /app && npm install --silent
    echo "[seed] Building frontend assets..."
    cd /app && npm run build --silent
fi

# ── 9. PERMISSIONS ────────────────────────────────────────────────────────────
chown -R www-data:www-data /app/storage /app/bootstrap/cache
chmod -R 775 /app/storage /app/bootstrap/cache

# ── 10. CACHE ─────────────────────────────────────────────────────────────────
php /app/artisan config:clear --quiet
php /app/artisan route:clear  --quiet
php /app/artisan view:clear   --quiet

echo "[seed] ── Bootstrap complete. Starting php-fpm. ─────────────────────────"

# Docker injects env vars from env_file at container start.  If APP_KEY was
# empty then and was generated during bootstrap, php-fpm would inherit the old
# empty value.  Re-export from the file so the correct key is in the environment.
APP_KEY="$(sed -n 's/^APP_KEY=//p' /app/.env)"
export APP_KEY

exec php-fpm
