<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class PublicApiController extends Controller
{
    public function status()
    {
        $connected = false;
        try { DB::connection()->getPdo(); $connected = true; } catch (\Exception $e) {}

        return response()->json([
            'status'  => 'ok',
            'app'     => config('app.name'),
            'env'     => config('app.env'),
            'php'     => PHP_VERSION,
            'laravel' => app()->version(),
            'db'      => ['driver' => config('database.default'), 'connected' => $connected],
            'mail'    => ['host' => config('mail.mailers.smtp.host'), 'port' => config('mail.mailers.smtp.port')],
            'time'    => now()->toIso8601String(),
        ]);
    }

    public function ping()
    {
        return response()->json(['pong' => true, 'time' => now()->toIso8601String()]);
    }
}
