<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $email    = env('DEMO_USER_EMAIL', 'admin@seed.local');
        $password = env('DEMO_USER_PASSWORD', 'password');

        $user = User::firstOrCreate(
            ['email' => $email],
            [
                'name'              => 'Admin',
                'password'          => Hash::make($password),
                'email_verified_at' => now(),
            ]
        );

        // Create a named demo token — plaintext written to /tmp so entrypoint can log it once
        if ($user->tokens()->where('name', 'demo-token')->doesntExist()) {
            $token = $user->createToken('demo-token');
            file_put_contents('/tmp/demo_api_token.txt', $token->plainTextToken);
        }
    }
}
