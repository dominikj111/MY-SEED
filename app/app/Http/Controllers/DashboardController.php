<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        return view('dashboard', [
            'userCount'    => DB::table('users')->count(),
            'sessionCount' => DB::table('sessions')->count(),
            'tokenCount'   => DB::table('personal_access_tokens')->count(),
        ]);
    }
}
