<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ config('app.name') }}</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, -apple-system, sans-serif; background: #f3f4f6;
               display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { background: #fff; border-radius: 10px; padding: 2.5rem; max-width: 560px;
                width: 100%; box-shadow: 0 4px 16px rgba(0,0,0,.08); }
        h1 { font-size: 1.8rem; margin-bottom: .35rem; }
        .meta { color: #9ca3af; font-size: .85rem; margin-bottom: 2rem; }
        .cta { display: inline-block; background: #6366f1; color: #fff; padding: .6rem 1.5rem;
               border-radius: 6px; text-decoration: none; font-weight: 600; margin-bottom: 2rem; }
        .cta:hover { background: #4f46e5; }
        h2 { font-size: .8rem; font-weight: 700; text-transform: uppercase; letter-spacing: .06em;
             color: #9ca3af; margin-bottom: .6rem; }
        ul { list-style: none; display: flex; flex-direction: column; gap: .35rem; margin-bottom: 1.5rem; }
        li { font-size: .9rem; }
        a { color: #6366f1; text-decoration: none; }
        a:hover { text-decoration: underline; }
        code { background: #f3f4f6; padding: .1em .35em; border-radius: 4px;
               font-size: .85em; color: #374151; }
    </style>
</head>
<body>
<div class="card">
    <h1>{{ config('app.name') }}</h1>
    <p class="meta">PHP {{ PHP_VERSION }} · Laravel {{ app()->version() }} · {{ config('database.default') }}</p>

    <a href="/login" class="cta">Sign in →</a>

    <h2>Auth &amp; API</h2>
    <ul>
        <li><a href="/login">/login</a> — session auth (sessions stored in PostgreSQL)</li>
        <li><a href="/api/v1/status">/api/v1/status</a> — public REST API</li>
        <li><a href="/api/v1/ping">/api/v1/ping</a> — public ping</li>
        <li><code>POST /api/v1/auth/token</code> — get bearer token</li>
        <li><code>GET /api/v1/me</code> — private REST API (Bearer token required)</li>
    </ul>

    <h2>Examples</h2>
    <ul>
        <li><a href="/spa/">/spa/</a> — stack status dashboard</li>
        <li><a href="/mail/send?to=test@example.com">/mail/send</a> — test email with attachment</li>
    </ul>

    <h2>Dev Tools</h2>
    <ul>
        <li><a href="http://localhost:{{ env('MAILPIT_WEB_PORT', 8025) }}" target="_blank">Mailpit</a> — email catcher</li>
        <li><a href="http://localhost:{{ env('ADMINER_PORT', 8081) }}" target="_blank">Adminer</a> — PostgreSQL browser</li>
    </ul>
</div>
</body>
</html>
