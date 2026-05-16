<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class MailExampleController extends Controller
{
    public function send(Request $request)
    {
        $to = $request->input('to', 'test@example.com');

        Mail::send([], [], function ($mail) use ($to) {
            $mail
                ->to($to)
                ->subject('Test email from the-seed')
                ->html('<h1>Hello from the-seed!</h1><p>Sent via the Laravel Mail facade through Mailpit (dev) or Gmail (prod).</p>')
                ->attach(__FILE__, ['as' => 'MailExampleController.php', 'mime' => 'text/plain']);
        });

        return response()->json([
            'sent_to' => $to,
            'mailpit' => 'http://localhost:' . env('MAILPIT_WEB_PORT', 8025),
        ]);
    }
}
