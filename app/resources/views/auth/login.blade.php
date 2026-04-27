<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign in · {{ config('app.name') }}</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, -apple-system, sans-serif; background: #f3f4f6;
               display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { background: #fff; border-radius: 10px; padding: 2rem; width: 100%;
                max-width: 380px; box-shadow: 0 4px 16px rgba(0,0,0,.08); }
        h1 { font-size: 1.4rem; margin-bottom: 1.5rem; color: #111; }
        label { display: block; font-size: .8rem; font-weight: 600; color: #374151;
                margin-bottom: .3rem; text-transform: uppercase; letter-spacing: .05em; }
        input[type=email], input[type=password] {
            width: 100%; padding: .55rem .75rem; border: 1px solid #d1d5db;
            border-radius: 6px; font-size: .95rem; margin-bottom: 1rem; background: #fafafa; }
        input:focus { outline: none; border-color: #6366f1; box-shadow: 0 0 0 3px #e0e7ff; background: #fff; }
        button { width: 100%; padding: .65rem; background: #6366f1; color: #fff; border: none;
                 border-radius: 6px; font-size: 1rem; font-weight: 600; cursor: pointer; }
        button:hover { background: #4f46e5; }
        .error { color: #dc2626; font-size: .85rem; margin-bottom: 1rem;
                 padding: .5rem .75rem; background: #fef2f2; border-radius: 6px; }
        .hint  { font-size: .78rem; color: #9ca3af; margin-top: 1.25rem; text-align: center; }
        a { color: #6366f1; text-decoration: none; }
    </style>
</head>
<body>
<div class="card">
    <h1>Sign in</h1>

    @if ($errors->any())
        <p class="error">{{ $errors->first() }}</p>
    @endif

    <form method="POST" action="/login">
        @csrf
        <label for="email">Email</label>
        <input type="email" id="email" name="email"
               value="{{ old('email') }}" required autofocus autocomplete="email">

        <label for="password">Password</label>
        <input type="password" id="password" name="password"
               required autocomplete="current-password">

        <button type="submit">Sign in</button>
    </form>

    <p class="hint"><a href="/">← Back to home</a></p>
</div>
</body>
</html>
