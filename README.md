# the-seed

> A Docker-based multi-stack development seed — PHP/Laravel · Python/Django+FastAPI · PostgreSQL · nginx · Mailpit

Two fully-featured application seeds running side-by-side behind a single nginx reverse proxy, sharing one PostgreSQL database and one Mailpit instance. Each stack demonstrates the same features independently: session auth, a protected dashboard, a contact form, public and private REST API, and email. Everything is configured through a single `.env` file.

## What's included

| Layer | Technology |
|---|---|
| Web server / reverse proxy | nginx (alpine) |
| PHP application | PHP 8.4-FPM · Laravel (latest) — served at `/` |
| Python application | Python 3.12 · Django 5 · FastAPI — served at `/py/` |
| Database | PostgreSQL 16 (shared by both stacks) |
| Email (dev) | Mailpit — catches all outgoing mail from both stacks |
| Email (prod) | Gmail SMTP via msmtp App Password (PHP) |
| DB browser | Adminer |
| PHP auth | Session auth (web) + Sanctum bearer tokens (API) |
| Python auth | Session auth (web) + DB-stored bearer tokens (API) |
| SSL | mkcert — locally trusted certificates, no browser warnings |
| Task runner | [just](https://github.com/casey/just) |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) ≥ 4.x
- [just](https://github.com/casey/just) — `brew install just`
- [mkcert](https://github.com/FiloSottile/mkcert) — optional, for HTTPS — `brew install mkcert && mkcert -install`

## Quickstart

```bash
git clone https://github.com/your-handle/the-seed && cd the-seed

# That's it — just up auto-creates .env and configs/msmtprc on first run
just up
```

First run takes ~3 minutes (downloads images, builds both stacks, migrates DB, seeds demo data). Both apps are accessible immediately — the PHP bootstrap takes the longest.

Both entrypoints run automatically on first start:

**PHP/Laravel:**
1. Creates a fresh Laravel project in `app/`
2. Runs all database migrations
3. Seeds a demo user and API token
4. Builds frontend assets via Vite

**Python/Django+FastAPI:**
1. Waits for PostgreSQL to be ready
2. Runs Django migrations (creates `auth_user`, `tokens_apitoken`, etc.)
3. Seeds the same demo user and a demo API token
4. Starts uvicorn (ASGI server)

```bash
just logs               # follow PHP container (longest bootstrap)
just logs-python        # follow Python container
just info               # print all service URLs for both stacks
just check              # smoke-test every feature across both stacks
```

## What's available after `just up`

### PHP / Laravel — at `http://localhost/`

| Feature | How to try it |
|---|---|
| **Landing page** | `http://localhost` |
| **Session login** | `http://localhost/login` → `admin@seed.local` / `password` |
| **Dashboard** | `http://localhost/dashboard` — protected, live DB stats |
| **Contact form** | `http://localhost/contact` — protected, sends email |
| **Public API** | `curl http://localhost/api/v1/status` |
| **Bearer token** | `curl -X POST http://localhost/api/v1/auth/token -H 'Content-Type: application/json' -d '{"email":"admin@seed.local","password":"password"}'` |
| **Private API** | `curl -H 'Authorization: Bearer <token>' http://localhost/api/v1/me` |
| **SPA** | `http://localhost/spa/` — vanilla JS fetching the API |
| **Email** | `http://localhost/mail/send?to=you@example.com` → check Mailpit |

### Python / Django + FastAPI — at `http://localhost/py/`

| Feature | How to try it |
|---|---|
| **Landing page** | `http://localhost/py/` |
| **Session login** | `http://localhost/py/login/` → `admin@seed.local` / `password` |
| **Dashboard** | `http://localhost/py/dashboard/` — protected, live DB stats + token list |
| **Contact form** | `http://localhost/py/contact/` — protected, sends email via Mailpit |
| **Public API** | `curl http://localhost/py/api/v1/status` |
| **Bearer token** | `curl -X POST http://localhost/py/api/v1/auth/token -H 'Content-Type: application/json' -d '{"email":"admin@seed.local","password":"password"}'` |
| **Private API** | `curl -H 'Authorization: Bearer <token>' http://localhost/py/api/v1/me` |
| **API Docs** | `http://localhost/py/api/v1/docs` — interactive Swagger UI |

### Shared services

| Service | URL |
|---|---|
| **Mailpit** | `http://localhost:8025` — all outgoing mail captured here |
| **Adminer** | `http://localhost:8081` — PostgreSQL browser (server: `postgres`) |

Run `just check` to verify everything in one shot:

```text
$ just check

── HTTP endpoints ───────────────────────────────────────────────────
  ✓  Landing page     GET /
  ✓  Login page       GET /login
  ✓  SPA              GET /spa/
  ✓  Health           GET /up
  ✓  Public API       GET /api/v1/status
  ✓  Public API       GET /api/v1/ping

── Sanctum bearer token ─────────────────────────────────────────────
  ✓  Token issued     POST /api/v1/auth/token → HTTP 201
  ✓  Private API      GET /api/v1/me (Bearer token)

── Email (Mailpit) ──────────────────────────────────────────────────
  ✓  Email sent       GET /mail/send
  ✓  Mailpit captured the message (3 total in inbox)

── Database (PostgreSQL) ────────────────────────────────────────────
  ✓  Table 'users' (1 rows)
  ✓  Table 'sessions' (1 rows)
  ✓  Table 'personal_access_tokens' (2 rows)
  ✓  Table 'migrations' (5 rows)

── Python · HTTP endpoints ──────────────────────────────────────────
  ✓  Landing page     GET /py/
  ✓  Login page       GET /py/login/
  ✓  Public API       GET /py/api/v1/status
  ✓  Public API       GET /py/api/v1/ping
  ✓  API Docs         GET /py/api/v1/docs

── Python · Bearer token ────────────────────────────────────────────
  ✓  Token issued     POST /py/api/v1/auth/token → HTTP 201
  ✓  Private API      GET /py/api/v1/me (Bearer token)

── Python · Database (PostgreSQL) ───────────────────────────────────
  ✓  Table 'auth_user' (1 rows)
  ✓  Table 'tokens_apitoken' (1 rows)
  ✓  Table 'django_migrations' (14 rows)
  ✓  Table 'django_session' (0 rows)

── Dev tools ────────────────────────────────────────────────────────
  ✓  Mailpit UI       http://localhost:8025
  ✓  Adminer          http://localhost:8081

  All 25 checks passed.
```

## Access

### PHP / Laravel

| Route | Notes |
|---|---|
| `http://localhost` | Landing page |
| `http://localhost/login` | `admin@seed.local` / `password` |
| `http://localhost/dashboard` | Protected — shows live DB stats |
| `http://localhost/contact` | Protected — sends email via Mailpit |
| `http://localhost/api/v1/status` | Public API |
| `http://localhost/api/v1/ping` | Public API |
| `http://localhost/api/v1/me` | Private API — Bearer token required |
| `http://localhost/spa/` | Vanilla JS SPA |
| `http://localhost/mail/send?to=you@example.com` | Sends email with attachment |
| `https://seed.local` | HTTPS — requires `just ssl` first |

### Python / Django + FastAPI

| Route | Notes |
|---|---|
| `http://localhost/py/` | Landing page |
| `http://localhost/py/login/` | `admin@seed.local` / `password` |
| `http://localhost/py/dashboard/` | Protected — DB stats + token list |
| `http://localhost/py/contact/` | Protected — contact form → Mailpit |
| `http://localhost/py/api/v1/status` | Public API |
| `http://localhost/py/api/v1/ping` | Public API |
| `http://localhost/py/api/v1/auth/token` | POST — issue a Bearer token |
| `http://localhost/py/api/v1/me` | GET — private, Bearer token required |
| `http://localhost/py/api/v1/token` | DELETE — revoke all tokens |
| `http://localhost/py/api/v1/docs` | Interactive Swagger UI |
| `http://localhost/py/admin/` | Django admin panel |

## Python seed — architecture

The Python service combines Django and FastAPI in a single uvicorn ASGI process. A lightweight dispatcher in [`config/asgi.py`](seed-django/config/asgi.py) routes requests by path prefix:

```
nginx /py/*
  └── uvicorn (python:8000)
        ├── /py/api/* ──► FastAPI
        │                  uses: pydantic models, dependency injection, async handlers
        └── /py/*    ──► Django
                           uses: ORM, sessions, forms, templates, management commands
```

**No path rewriting in nginx** — the full `/py/…` path reaches uvicorn. Django URL patterns include the `py/` prefix explicitly. This keeps the routing transparent and easy to follow.

### Key files

```
seed-django/
├── config/
│   ├── asgi.py        # ASGI dispatcher: FastAPI vs Django by path
│   ├── settings.py    # all Django settings (DB, email, logging, auth backend)
│   └── urls.py        # Django URL patterns (include py/ prefix)
├── web/
│   ├── backends.py    # custom email-based auth backend
│   ├── views.py       # index, login, logout, dashboard, contact
│   ├── forms.py       # ContactForm (Django form validation)
│   └── templates/     # Bootstrap 5 templates (base + 4 pages)
├── api/
│   ├── main.py        # FastAPI app factory, mounts routers at /py/api/v1
│   ├── auth.py        # Bearer token dependency (async DB lookup)
│   └── routers/
│       ├── public.py  # /status, /ping — no auth
│       └── private.py # /auth/token, /me, /token — auth required
├── tokens/
│   ├── models.py      # APIToken model (user FK, random token, name)
│   ├── admin.py       # Django admin registration
│   └── management/commands/seed_demo.py  # idempotent demo user + token
├── entrypoint.sh      # wait for PG → migrate → seed → uvicorn
└── requirements.txt   # Django, FastAPI, uvicorn, psycopg
```

### Authentication

**Web (Django sessions):** Standard Django session auth. A custom backend in `web/backends.py` authenticates by email address (Django's default uses username). Login at `/py/login/` with `admin@seed.local` / `password`.

**API (Bearer tokens):** Tokens are stored in `tokens_apitoken` (PostgreSQL). FastAPI's `Depends(get_current_user)` in `api/auth.py` looks up the token asynchronously using `sync_to_async`. Issue a token via `POST /py/api/v1/auth/token`.

## PHP REST API

### Public endpoints (no auth)

```bash
curl http://localhost/api/v1/status
curl http://localhost/api/v1/ping
```

### Issue a bearer token

```bash
curl -s -X POST http://localhost/api/v1/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@seed.local","password":"password","token_name":"my-token"}'
# → {"token":"1|...","token_type":"Bearer","user":{...}}
```

```bash
just logs | grep "Demo API token"   # demo token printed on first start
```

### Private endpoints (Bearer token required)

```bash
TOKEN="1|your-token-here"
curl -H "Authorization: Bearer $TOKEN" http://localhost/api/v1/me
curl -H "Authorization: Bearer $TOKEN" http://localhost/api/v1/token/info
curl -X DELETE -H "Authorization: Bearer $TOKEN" http://localhost/api/v1/token
```

## Python REST API

### Public endpoints (no auth)

```bash
curl http://localhost/py/api/v1/status
curl http://localhost/py/api/v1/ping
```

### Issue a bearer token

```bash
curl -s -X POST http://localhost/py/api/v1/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@seed.local","password":"password","token_name":"my-token"}' \
  | python3 -m json.tool
# → {"token":"...","token_type":"Bearer","user":{...}}
```

```bash
just logs-python | grep "Demo API token"   # demo token printed on first start
```

### Private endpoints (Bearer token required)

```bash
TOKEN="your-token-here"
curl -H "Authorization: Bearer $TOKEN" http://localhost/py/api/v1/me
curl -X DELETE -H "Authorization: Bearer $TOKEN" http://localhost/py/api/v1/token
```

### Interactive API docs

```
http://localhost/py/api/v1/docs    # Swagger UI
http://localhost/py/api/v1/redoc   # ReDoc
```

## HTTPS with custom domain

### 1. Add the domain to `/etc/hosts`

```bash
echo "127.0.0.1  seed.local" | sudo tee -a /etc/hosts
```

### 2. Generate a locally-trusted certificate

```bash
just ssl
# Requires: brew install mkcert && mkcert -install  (once per machine)
```

Certs are written to `docker/certs/seed.pem` and `docker/certs/seed-key.pem`.

### 3. Enable the HTTPS block in `nginx/app.conf`

Open [nginx/app.conf](nginx/app.conf) and make two edits:

- Replace the `server { listen 80; ... }` block with the redirect block shown in the comments.
- Uncomment the `server { listen 443 ssl; ... }` block below it.

The `/py/` location block is included in the HTTPS example comments too.

### 4. Update `.env`

```dotenv
APP_URL=https://seed.local
APP_DOMAIN=seed.local
```

### 5. Restart nginx

```bash
just restart nginx
```

`https://seed.local` and `https://seed.local/py/` both work with a green padlock.

## Configuration

All settings live in `.env` — one file drives Docker Compose, Laravel, and the Python app.

| Variable | Default | Purpose |
|---|---|---|
| `PHP_VERSION` | `8.4` | PHP image tag |
| `NODE_VERSION` | `20` | Node.js version |
| `APP_DOMAIN` | `seed.local` | Custom local domain for HTTPS |
| `DB_DATABASE` | `seeddb` | PostgreSQL database (shared by both stacks) |
| `DB_USERNAME` | `seeduser` | PostgreSQL user |
| `DB_PASSWORD` | `secret` | PostgreSQL password |
| `DEMO_USER_EMAIL` | `admin@seed.local` | Seeded user email (both stacks) |
| `DEMO_USER_PASSWORD` | `password` | Seeded user password (both stacks) |
| `HTTP_PORT` | `80` | nginx HTTP port |
| `HTTPS_PORT` | `443` | nginx HTTPS port |

**Config files editable on the host (no rebuild required):**

| File | Purpose |
|---|---|
| `configs/php.ini` | PHP runtime settings |
| `configs/php-fpm.d/www.conf` | FPM pool size, slow log |
| `configs/msmtprc` | Mail relay (Mailpit / Gmail) |
| `nginx/app.conf` | Virtual host, `/py/` proxy block, SSL block |
| `nginx/ssl.conf` | TLS protocols and ciphers |
| `docker/entrypoint.sh` | PHP container bootstrap |
| `seed-django/entrypoint.sh` | Python container bootstrap |
| `seed-django/config/settings.py` | Django settings |

After editing nginx or PHP config: `just restart nginx` or `docker compose restart php` — no rebuild.  
After editing Python code: uvicorn `--reload` picks it up automatically.

## Email

**Development (default):** All mail from both stacks is captured by Mailpit at `http://localhost:8025`. No real emails are sent.

**PHP production:** Edit `configs/msmtprc`, fill in your Gmail App Password, and change the default account to `google`. Then update the `MAIL_*` variables in `.env`.

**Python production:** Update `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USE_TLS`, and credentials in `seed-django/config/settings.py` (or add corresponding env vars).

> Gmail requires an [App Password](https://myaccount.google.com/apppasswords) (not your login password). Enable 2-Step Verification first.

## Logs

All logs are written to `logs/` and readable from the host even when Docker is stopped:

| Directory | Contents |
|---|---|
| `logs/nginx/` | `access.log`, `error.log` |
| `logs/php/` | `fpm-error.log`, `slow.log`, `error.log` |
| `logs/app/` | Laravel's `laravel.log` |
| `logs/postgres/` | `postgresql.log` |
| `logs/mail/` | `msmtp.log`, `php_mail.log` |
| `logs/python/` | `app.log` — Django + FastAPI application log |

```bash
just logs-app          # tail Laravel log
just logs-nginx        # tail nginx access + error
just logs-db           # tail PostgreSQL log
just logs-mail         # tail mail log
just logs-seed-django   # tail Python application log
```

## just recipes

```text
── Lifecycle ──────────────────────────────────────────────────────────
just up              start all containers (PHP + Python + shared services)
just stop            stop containers
just rebuild         rebuild PHP image and start
just py-rebuild      rebuild Python image and start
just fresh           full reset (wipes DB, generated app files, logs)
just restart <svc>   restart one service (nginx, php, python, postgres …)

── Check & info ───────────────────────────────────────────────────────
just check           smoke-test all features across both stacks
just info            print all service URLs

── SSL ────────────────────────────────────────────────────────────────
just ssl             generate HTTPS certs via mkcert

── PHP / Laravel ──────────────────────────────────────────────────────
just logs            follow PHP container stdout
just logs-app        tail Laravel application log
just logs-nginx      tail nginx logs
just logs-db         tail PostgreSQL log
just shell           bash inside PHP container
just artisan <cmd>   run Artisan command
just composer <cmd>  run Composer inside container
just npm <cmd>       run npm inside container

── Python / Django + FastAPI ──────────────────────────────────────────
just py-shell           bash inside Python container
just py-manage <cmd>    run Django management command
just logs-python        follow Python container stdout
just logs-seed-django    tail Python application log

── Database ───────────────────────────────────────────────────────────
just db              PostgreSQL interactive shell
just db-backup       dump DB to backup.sql
just db-restore      restore DB from backup.sql
```

## Project structure

```
the-seed/
├── docker/
│   ├── php/Dockerfile      # PHP + extensions
│   ├── entrypoint.sh       # PHP bootstrap: create Laravel, migrate, seed, start fpm
│   └── certs/              # mkcert SSL certs (gitignored)
├── nginx/
│   ├── nginx.conf          # global config, upstreams: php_fpm + python_asgi
│   ├── app.conf            # routes: / → PHP, /py/ → Python, SSL block
│   └── ssl.conf            # TLS protocols and ciphers
├── seed-django/             # Python seed (committed in full)
│   ├── Dockerfile          # python:3.12-slim + psycopg + pip install
│   ├── entrypoint.sh       # wait for PG → migrate → seed → uvicorn
│   ├── requirements.txt    # Django, FastAPI, uvicorn, psycopg
│   ├── manage.py
│   ├── config/
│   │   ├── settings.py     # Django settings
│   │   ├── urls.py         # URL conf (includes py/ prefix)
│   │   └── asgi.py         # ASGI dispatcher (FastAPI vs Django)
│   ├── web/                # Django app: views, forms, templates
│   │   ├── backends.py     # email-based auth backend
│   │   ├── views.py
│   │   ├── forms.py
│   │   └── templates/      # Bootstrap 5 (base + index/login/dashboard/contact)
│   ├── api/                # FastAPI app
│   │   ├── main.py         # FastAPI factory, router registration
│   │   ├── auth.py         # Bearer token dependency
│   │   └── routers/
│   │       ├── public.py   # /status, /ping
│   │       └── private.py  # /auth/token, /me, /token
│   └── tokens/             # Django app: APIToken model
│       ├── models.py
│       ├── admin.py
│       ├── migrations/
│       └── management/commands/seed_demo.py
├── configs/
│   ├── php.ini
│   ├── php-fpm.d/www.conf
│   ├── msmtprc.example
│   └── fastcgi-params.conf
├── seed-laravel/           # Laravel project (auto-created on first start, gitignored)
├── logs/
│   ├── nginx/
│   ├── php/
│   ├── app/                # Laravel storage/logs
│   ├── postgres/
│   ├── mail/
│   └── python/             # Django + FastAPI app.log
├── database/               # PostgreSQL data volume (gitignored)
├── .env.example
├── docker-compose.yml
├── Justfile
└── README.md
```

## PostgreSQL tables after first start

Both stacks share the same `seeddb` database. Table names don't conflict — Django uses its conventional prefixed names.

### PHP / Laravel tables

| Table | Purpose |
|---|---|
| `users` | Seeded demo user |
| `sessions` | Browser sessions |
| `personal_access_tokens` | Sanctum API tokens |
| `migrations` | Laravel migration history |
| `jobs`, `failed_jobs`, `cache` | Laravel defaults |

### Python / Django tables

| Table | Purpose |
|---|---|
| `auth_user` | Seeded demo user (same email, separate record) |
| `django_session` | Browser sessions |
| `tokens_apitoken` | FastAPI bearer tokens |
| `django_migrations` | Django migration history |
| `auth_group`, `auth_permission` | Django permission system |
| `django_admin_log` | Admin audit log |

## Contributing

Contributions are welcome.

**PHP app:** The `seed-laravel/` directory contains only custom source files (controllers, models, routes, views, seeders). Standard Laravel boilerplate is auto-generated on first run and gitignored.

**Python app:** The entire `seed-django/` directory is committed. No generated files — what you see is what runs.

1. Fork the repo and create a feature branch
2. Make changes in `docker/`, `nginx/`, `configs/`, `seed-laravel/`, or `seed-django/`
3. Test with `just fresh` then `just check` to verify a clean first-run experience
4. Open a pull request with a clear description

## License

MIT
