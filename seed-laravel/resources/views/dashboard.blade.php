<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard · {{ config('app.name') }}</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, -apple-system, sans-serif; background: #f3f4f6; color: #111; min-height: 100vh; }
        header { background: #fff; border-bottom: 1px solid #e5e7eb; padding: .85rem 2rem;
                 display: flex; justify-content: space-between; align-items: center; }
        header strong { font-size: 1rem; }
        .user { font-size: .85rem; color: #6b7280; display: flex; gap: 1rem; align-items: center; }
        .badge { background: #d1fae5; color: #065f46; padding: .15rem .6rem;
                 border-radius: 99px; font-size: .75rem; font-weight: 600; }
        main { max-width: 800px; margin: 2rem auto; padding: 0 1rem; }
        h1 { font-size: 1.5rem; margin-bottom: .5rem; }
        .subtitle { color: #6b7280; font-size: .9rem; margin-bottom: 2rem; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px,1fr)); gap: 1rem; margin-bottom: 1.5rem; }
        .stat { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 1.25rem; }
        .stat strong { display: block; font-size: 2.5rem; font-weight: 700; color: #6366f1; }
        .stat span { font-size: .8rem; color: #6b7280; }
        .section { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px;
                   padding: 1.25rem; margin-bottom: 1rem; }
        h2 { font-size: 1rem; font-weight: 700; margin-bottom: .75rem; color: #374151; }
        ul { list-style: none; display: flex; flex-direction: column; gap: .4rem; }
        li { font-size: .9rem; }
        li a { color: #6366f1; text-decoration: none; }
        li a:hover { text-decoration: underline; }
        li code { color: #374151; font-size: .85rem; }
        form button { background: none; border: none; color: #9ca3af; cursor: pointer;
                      font-size: .85rem; text-decoration: underline; padding: 0; }
        form button:hover { color: #dc2626; }
    </style>
</head>
<body>
<header>
    <strong>{{ config('app.name') }}</strong>
    <div class="user">
        <span class="badge">authenticated</span>
        <span>{{ auth()->user()->email }}</span>
        <form method="POST" action="/logout">
            @csrf
            <button type="submit">Sign out</button>
        </form>
    </div>
</header>

<main>
    <h1>Dashboard</h1>
    <p class="subtitle">Live queries against PostgreSQL.</p>

    <div class="stats">
        <div class="stat">
            <strong>{{ $userCount }}</strong>
            <span>users in <code>users</code></span>
        </div>
        <div class="stat">
            <strong>{{ $sessionCount }}</strong>
            <span>sessions in <code>sessions</code></span>
        </div>
        <div class="stat">
            <strong>{{ $tokenCount }}</strong>
            <span>API tokens in <code>personal_access_tokens</code></span>
        </div>
    </div>

    <div class="section">
        <h2>REST API</h2>
        <ul>
            <li><a href="/api/v1/status">/api/v1/status</a> — public: health + DB status</li>
            <li><a href="/api/v1/ping">/api/v1/ping</a> — public: ping</li>
            <li><code>POST /api/v1/auth/token</code> — issue bearer token</li>
            <li><code>GET /api/v1/me</code> — private: your user (Bearer token required)</li>
            <li><code>GET /api/v1/token/info</code> — private: token metadata</li>
            <li><code>DELETE /api/v1/token</code> — private: revoke token</li>
        </ul>
    </div>

    <div class="section">
        <h2>Examples &amp; Tools</h2>
        <ul>
            <li><a href="/contact">/contact</a> — contact form with email (protected)</li>
            <li><a href="/spa/">/spa/</a> — vanilla JS SPA demo</li>
            <li><a href="/mail/send?to=test@example.com">/mail/send</a> — send test email with attachment</li>
            <li><a href="http://localhost:{{ env('MAILPIT_WEB_PORT', 8025) }}" target="_blank">Mailpit</a> — captured emails</li>
            <li><a href="http://localhost:{{ env('ADMINER_PORT', 8081) }}" target="_blank">Adminer</a> — PostgreSQL browser</li>
        </ul>
    </div>
</main>
</body>
</html>
