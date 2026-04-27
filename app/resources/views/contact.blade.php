<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact · {{ config('app.name') }}</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, -apple-system, sans-serif; background: #f3f4f6; color: #111; min-height: 100vh; }
        header { background: #fff; border-bottom: 1px solid #e5e7eb; padding: .85rem 2rem;
                 display: flex; justify-content: space-between; align-items: center; }
        header strong { font-size: 1rem; }
        .user { font-size: .85rem; color: #6b7280; display: flex; gap: 1rem; align-items: center; }
        main { max-width: 600px; margin: 2.5rem auto; padding: 0 1rem; }
        h1 { font-size: 1.4rem; margin-bottom: .35rem; }
        .sub { color: #6b7280; font-size: .85rem; margin-bottom: 2rem; }
        .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 1.75rem; }
        label { display: block; font-size: .8rem; font-weight: 700; color: #374151;
                text-transform: uppercase; letter-spacing: .05em; margin-bottom: .3rem; }
        input[type=email], input[type=text], textarea {
            width: 100%; padding: .55rem .75rem; border: 1px solid #d1d5db;
            border-radius: 6px; font-size: .95rem; font-family: inherit;
            background: #fafafa; margin-bottom: 1.1rem; }
        input:focus, textarea:focus {
            outline: none; border-color: #6366f1; box-shadow: 0 0 0 3px #e0e7ff; background: #fff; }
        textarea { resize: vertical; min-height: 130px; }
        button[type=submit] { background: #6366f1; color: #fff; border: none; border-radius: 6px;
                 padding: .65rem 1.5rem; font-size: 1rem; font-weight: 600; cursor: pointer; }
        button[type=submit]:hover { background: #4f46e5; }
        .success { background: #d1fae5; color: #065f46; border: 1px solid #a7f3d0;
                   border-radius: 6px; padding: .75rem 1rem; margin-bottom: 1.25rem; font-size: .9rem; }
        .error-msg { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5;
                     border-radius: 6px; padding: .75rem 1rem; margin-bottom: 1.25rem; font-size: .9rem; }
        .mailpit-note { font-size: .8rem; color: #9ca3af; margin-top: 1.25rem; }
        .mailpit-note a { color: #6366f1; }
        nav { margin-top: 1.25rem; font-size: .85rem; }
        nav a { color: #6366f1; text-decoration: none; margin-right: 1rem; }
        .logout-btn { background: none; border: none; color: #9ca3af; cursor: pointer;
                      font-size: .85rem; text-decoration: underline; padding: 0; }
        .logout-btn:hover { color: #dc2626; }
    </style>
</head>
<body>
<header>
    <strong>{{ config('app.name') }}</strong>
    <div class="user">
        <span>{{ auth()->user()->email }}</span>
        <form method="POST" action="/logout">
            @csrf
            <button type="submit" class="logout-btn">Sign out</button>
        </form>
    </div>
</header>

<main>
    <h1>Contact form</h1>
    <p class="sub">Protected route — only available when signed in. Email is captured by Mailpit in development.</p>

    @if (session('success'))
        <div class="success">
            {{ session('success') }}
            — <a href="http://localhost:{{ env('MAILPIT_WEB_PORT', 8025) }}" target="_blank">Open Mailpit →</a>
        </div>
    @endif

    @if ($errors->any())
        <div class="error-msg">{{ $errors->first() }}</div>
    @endif

    <div class="card">
        <form method="POST" action="/contact">
            @csrf

            <label for="to">To</label>
            <input type="email" id="to" name="to"
                   value="{{ old('to', 'test@example.com') }}" required>

            <label for="subject">Subject</label>
            <input type="text" id="subject" name="subject"
                   value="{{ old('subject', 'Hello from the-seed') }}" required maxlength="150">

            <label for="message">Message</label>
            <textarea id="message" name="message" required
                      maxlength="5000">{{ old('message', "Hi,\n\nThis is a test email sent from the-seed contact form.\n\nRegards,\n" . auth()->user()->name) }}</textarea>

            <button type="submit">Send email</button>
        </form>

        <p class="mailpit-note">
            Dev mode: all mail is captured by
            <a href="http://localhost:{{ env('MAILPIT_WEB_PORT', 8025) }}" target="_blank">Mailpit</a>
            — no real email is sent.
        </p>
    </div>

    <nav>
        <a href="/dashboard">← Dashboard</a>
        <a href="/">Home</a>
    </nav>
</main>
</body>
</html>
