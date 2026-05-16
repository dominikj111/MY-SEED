<?php

use App\Http\Controllers\Api\AuthTokenController;
use App\Http\Controllers\Api\PrivateApiController;
use App\Http\Controllers\Api\PublicApiController;
use Illuminate\Support\Facades\Route;

// Public API — no authentication required
Route::prefix('v1')->group(function () {
    Route::get('/status', [PublicApiController::class, 'status']);
    Route::get('/ping',   [PublicApiController::class, 'ping']);
    Route::post('/auth/token', [AuthTokenController::class, 'issue']);
});

// Private API — Laravel Sanctum bearer token required
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    Route::get('/me',         [PrivateApiController::class, 'me']);
    Route::get('/token/info', [PrivateApiController::class, 'tokenInfo']);
    Route::delete('/token',   [PrivateApiController::class, 'revoke']);
});
