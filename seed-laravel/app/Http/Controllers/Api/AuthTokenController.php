<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthTokenController extends Controller
{
    public function issue(Request $request)
    {
        $request->validate([
            'email'      => ['required', 'email'],
            'password'   => ['required'],
            'token_name' => ['nullable', 'string', 'max:64'],
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        $token = $user->createToken($request->input('token_name', 'api-token'));

        return response()->json([
            'token'      => $token->plainTextToken,
            'token_type' => 'Bearer',
            'user'       => ['id' => $user->id, 'email' => $user->email],
        ], 201);
    }
}
