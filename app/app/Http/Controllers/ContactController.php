<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class ContactController extends Controller
{
    public function show()
    {
        return view('contact');
    }

    public function send(Request $request)
    {
        $data = $request->validate([
            'to'      => ['required', 'email'],
            'subject' => ['required', 'string', 'max:150'],
            'message' => ['required', 'string', 'max:5000'],
        ]);

        $sender = auth()->user();

        Mail::send([], [], function ($mail) use ($data, $sender) {
            $mail
                ->to($data['to'])
                ->subject($data['subject'])
                ->html(
                    '<p>From: ' . e($sender->name) . ' &lt;' . e($sender->email) . '&gt;</p>' .
                    '<hr>' .
                    nl2br(e($data['message']))
                );
        });

        return back()->with('success', 'Email sent to ' . $data['to'] . ' — check Mailpit.');
    }
}
