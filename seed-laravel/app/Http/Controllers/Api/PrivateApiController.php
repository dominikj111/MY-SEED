<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PrivateApiController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'id'         => $user->id,
            'name'       => $user->name,
            'email'      => $user->email,
            'created_at' => $user->created_at,
        ]);
    }

    public function tokenInfo(Request $request)
    {
        $token = $request->user()->currentAccessToken();
        return response()->json([
            'id'        => $token->id,
            'name'      => $token->name,
            'abilities' => $token->abilities,
            'last_used' => $token->last_used_at,
            'created'   => $token->created_at,
        ]);
    }

    public function revoke(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Token revoked.']);
    }
}
