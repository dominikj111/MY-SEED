<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\ContactController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MailExampleController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => view('welcome'));

// Session authentication
Route::get('/login',   [AuthController::class, 'showLogin'])->name('login')->middleware('guest');
Route::post('/login',  [AuthController::class, 'login'])->middleware('guest');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout')->middleware('auth');

// Protected routes
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/contact',   [ContactController::class, 'show'])->name('contact');
    Route::post('/contact',  [ContactController::class, 'send']);
});

// Quick mail example (no auth — useful for testing without login)
Route::get('/mail/send', [MailExampleController::class, 'send']);
