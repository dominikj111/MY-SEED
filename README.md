# the-seed

> A Docker-based PHP development seed — Laravel · PostgreSQL · nginx SSL · Mailpit · Sanctum API

A ready-to-use local development environment you can clone and build on. Ships with session auth, a public and private REST API, a vanilla JS SPA, email sending with attachments, and HTTPS via a custom local domain. Everything is configured through a single `.env` file.

## What's included

| Layer | Technology |
|---|---|
| Web server / reverse proxy | nginx (alpine) |
| Application | PHP 8.4-FPM · Laravel (latest) |
| Database | PostgreSQL 16 |
| Email (dev) | Mailpit — catches all outgoing mail |
| Email (prod) | Gmail SMTP via msmtp App Password |
| DB browser | Adminer |
| Auth | Session auth (web) + Sanctum bearer tokens (API) |
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

First run takes ~2 minutes (downloads images, installs Composer/npm dependencies, migrates DB). Access the app at `http://localhost` while it bootstraps.

On first start the entrypoint automatically:
1. Creates a fresh Laravel project in `app/`
2. Runs all database migrations (PostgreSQL)
3. Seeds a demo user and API token (credentials printed to container logs)
4. Builds frontend assets via Vite

```bash
just logs    # watch bootstrap progress
just info    # print all service URLs once ready
just check   # smoke-test every feature (see below)
```

## What's available after `just up`

Once the bootstrap completes (`just logs` shows "Bootstrap complete"), everything below is live and working:

| Feature | How to try it |
|---|---|
| **Landing page** | `http://localhost` |
| **Session login** | `http://localhost/login` → `admin@seed.local` / `password` |
| **Dashboard** | `http://localhost/dashboard` — protected, live DB stats |
| **Public API** | `curl http://localhost/api/v1/status` |
| **Bearer token** | `curl -X POST http://localhost/api/v1/auth/token -H 'Content-Type: application/json' -d '{"email":"admin@seed.local","password":"password"}'` |
| **Private API** | `curl -H 'Authorization: Bearer <token>' http://localhost/api/v1/me` |
| **SPA** | `http://localhost/spa/` — vanilla JS fetching the API |
| **Email** | `http://localhost/mail/send?to=you@example.com` → check Mailpit |
| **Mailpit** | `http://localhost:8025` — all outgoing mail is captured here |
| **Adminer** | `http://localhost:8081` — PostgreSQL browser (server: `postgres`) |

Run `just check` to verify all of the above in one shot:

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

── Dev tools ────────────────────────────────────────────────────────
  ✓  Mailpit UI       http://localhost:8025
  ✓  Adminer          http://localhost:8081

  All 14 checks passed.
```

## Access

| Service | URL | Notes |
|---|---|---|
| App (HTTPS) | `https://seed.local` | requires `just ssl` first |
| App (HTTP) | `http://localhost` | works immediately |
| Login | `/login` | admin@seed.local / password |
| Dashboard | `/dashboard` | protected, shows live DB stats |
| Contact form | `/contact` | protected, sends email via Mailpit |
| Public API | `/api/v1/status` | no auth |
| Public API | `/api/v1/ping` | no auth |
| Private API | `/api/v1/me` | Bearer token required |
| SPA demo | `/spa/` | vanilla JS |
| Email | `/mail/send?to=you@example.com` | sends with attachment |
| Mailpit | `http://localhost:8025` | captured emails |
| Adminer | `http://localhost:8081` | PostgreSQL browser |

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

- Replace the `server { listen 80; ... }` block with the redirect block shown in the comments:

  ```nginx
  server {
      listen 80;
      server_name _;
      return 301 https://$host$request_uri;
  }
  ```

- Uncomment the `server { listen 443 ssl; ... }` block below it.

### 4. Update `.env`

```dotenv
APP_URL=https://seed.local
APP_DOMAIN=seed.local
```

### 5. Restart nginx

```bash
just restart nginx
```

`https://seed.local` now works with a green padlock — mkcert installs a local CA that the OS and all browsers trust. No certificate warnings.

## REST API

### Public endpoints (no auth)

```bash
curl https://seed.local/api/v1/status
curl https://seed.local/api/v1/ping
```

### Issue a bearer token

```bash
curl -s -X POST https://seed.local/api/v1/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@seed.local","password":"password","token_name":"my-token"}'
# → {"token":"1|...","token_type":"Bearer","user":{...}}
```

A demo token is also printed to the container logs on first start:
```bash
just logs | grep "Demo API token"
```

### Private endpoints (Bearer token required)

```bash
TOKEN="1|your-token-here"

curl -H "Authorization: Bearer $TOKEN" https://seed.local/api/v1/me
curl -H "Authorization: Bearer $TOKEN" https://seed.local/api/v1/token/info
curl -X DELETE -H "Authorization: Bearer $TOKEN" https://seed.local/api/v1/token
```

## Configuration

All settings are in `.env` — single source of truth for Docker Compose, Laravel, and `just`.

Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `PHP_VERSION` | `8.3` | PHP image tag (triggers rebuild) |
| `NODE_VERSION` | `20` | Node.js version (triggers rebuild) |
| `APP_DOMAIN` | `seed.local` | Custom local domain for HTTPS |
| `DB_DATABASE` | `seeddb` | PostgreSQL database name |
| `DB_USERNAME` | `seeduser` | PostgreSQL user |
| `DB_PASSWORD` | `secret` | PostgreSQL password |
| `DEMO_USER_EMAIL` | `admin@seed.local` | Seeded user email |
| `DEMO_USER_PASSWORD` | `password` | Seeded user password |
| `HTTP_PORT` | `80` | nginx HTTP port |
| `HTTPS_PORT` | `443` | nginx HTTPS port |

**Config files editable on the host (no rebuild required):**

| File | Purpose |
|---|---|
| `configs/php.ini` | PHP runtime settings |
| `configs/php-fpm.d/www.conf` | FPM pool size, slow log |
| `configs/msmtprc` | Mail relay (Mailpit / Gmail) |
| `nginx/app.conf` | Virtual host, SSL block |
| `nginx/ssl.conf` | TLS protocols and ciphers |
| `docker/entrypoint.sh` | Container bootstrap logic |

After editing any of these: `docker compose restart php` or `just restart nginx` — no rebuild.

## Email

**Development (default):** All mail is captured by Mailpit at `http://localhost:8025`. No real emails are sent.

**Production:** Edit `configs/msmtprc`, fill in your Gmail App Password, and change the default account to `google`. Then update the `MAIL_*` variables in `.env`.

> Gmail requires a [App Password](https://myaccount.google.com/apppasswords) (not your login password). Enable 2-Step Verification first.

## Logs

All logs are written to `logs/` and readable from the host even when Docker is stopped:

| Directory | Contents |
|---|---|
| `logs/nginx/` | `access.log`, `error.log` |
| `logs/php/` | `fpm-error.log`, `slow.log`, `error.log` |
| `logs/app/` | Laravel's `laravel.log` |
| `logs/postgres/` | `postgresql.log` |
| `logs/mail/` | `msmtp.log`, `php_mail.log` |

```bash
just logs-app     # tail Laravel log
just logs-nginx   # tail nginx access + error
just logs-db      # tail PostgreSQL log
just logs-mail    # tail mail log
```

## just recipes

```text
just up              start containers
just stop            stop containers
just rebuild         rebuild PHP image and start
just fresh           full reset (wipes DB, generated app files, logs)
just restart <svc>   restart one service (nginx, php, postgres …)
just check           smoke-test all features (HTTP, auth, email, DB, tools)
just ssl             generate HTTPS certs via mkcert
just logs            follow PHP container stdout
just logs-app        tail Laravel application log
just logs-nginx      tail nginx logs
just logs-db         tail PostgreSQL log
just shell           bash inside PHP container
just artisan <cmd>   run Artisan command
just composer <cmd>  run Composer inside container
just npm <cmd>       run npm inside container
just db              PostgreSQL interactive shell
just db-backup       dump DB to backup.sql
just db-restore      restore DB from backup.sql
just info            print all service URLs
```

## Project structure

```
the-seed/
├── docker/
│   ├── php/Dockerfile      # installs system deps and PHP extensions only
│   ├── entrypoint.sh       # bootstrap: creates Laravel, migrates, seeds, starts fpm
│   └── certs/              # mkcert SSL certs (gitignored)
├── nginx/
│   ├── nginx.conf          # global config, upstream php_fpm block
│   ├── app.conf            # HTTP→HTTPS redirect + HTTPS server block
│   └── ssl.conf            # TLS protocols and ciphers
├── configs/
│   ├── php.ini             # PHP runtime (bind-mounted, edit without rebuild)
│   ├── php-fpm.d/www.conf  # FPM pool (bind-mounted, edit without rebuild)
│   ├── msmtprc.example     # mail relay template
│   └── fastcgi-params.conf # nginx FastCGI parameter overrides
├── app/                    # Laravel project (auto-created on first start)
├── logs/                   # all service logs (readable offline)
│   ├── nginx/
│   ├── php/
│   ├── app/                # Laravel storage/logs mapped here
│   ├── postgres/
│   └── mail/
├── database/               # PostgreSQL data volume (gitignored)
├── .env.example            # single source of truth for all config
├── docker-compose.yml
├── Justfile
└── README.md
```

## PostgreSQL tables after first start

| Table | Purpose |
|---|---|
| `users` | Seeded demo user |
| `sessions` | Browser sessions (`SESSION_DRIVER=database`) |
| `personal_access_tokens` | Sanctum API tokens |
| `migrations` | Migration history |
| `jobs`, `failed_jobs`, `cache` | Laravel defaults |

## Contributing

Contributions are welcome. The `app/` directory contains only the custom source files that survive `composer create-project` (controllers, models, routes, views, seeders, `bootstrap/app.php`). Standard Laravel boilerplate is auto-generated on first run and gitignored — don't commit it.

1. Fork the repo and create a feature branch
2. Make changes in `docker/`, `nginx/`, `configs/`, `app/`, or root config files
3. Test with `just fresh` then `just check` to verify a clean first-run experience
4. Open a pull request with a clear description

## License

MIT
