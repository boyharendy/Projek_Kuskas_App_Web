<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\WebQrSession;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class QrLoginController extends Controller
{
    /**
     * Generate a new QR code login session locally.
     */
    public function generateSession()
    {
        $sessionId = (string) Str::uuid();
        $token = Str::random(32);

        WebQrSession::create([
            'session_id' => $sessionId,
            'token' => $token,
            'status' => 'pending',
        ]);

        return response()->json([
            'session_id' => $sessionId,
            'token' => $token,
            'qr_data' => json_encode([
                'type' => 'kuskas_web_login',
                'session_id' => $sessionId,
            ]),
        ]);
    }

    /**
     * Authenticate a session (called by the mobile app).
     */
    public function authenticateSession(Request $request)
    {
        $request->validate([
            'session_id' => 'required|uuid',
            'kuskas_user_id' => 'required|uuid',
            'name' => 'nullable|string',
            'email' => 'nullable|email',
        ]);

        $session = WebQrSession::where('session_id', $request->session_id)->first();

        if (!$session) {
            return response()->json(['error' => 'Sesi QR tidak ditemukan atau sudah kedaluwarsa.'], 404);
        }

        $session->status = 'authenticated';
        $session->kuskas_user_id = $request->kuskas_user_id;
        $session->save();

        // Create or update local Laravel user
        $email = $request->email ?? 'anon-' . substr($request->kuskas_user_id, 0, 8) . '@kuskas.app';
        $name = $request->name ?? 'Kuskas User';

        $user = User::find($request->kuskas_user_id);

        if (!$user) {
            $user = User::create([
                'id' => $request->kuskas_user_id,
                'full_name' => $name,
                'email' => $email,
            ]);
        } else {
            if ($user->full_name !== $name || $user->email !== $email) {
                $user->full_name = $name;
                $user->email = $email;
                $user->save();
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Sesi berhasil diautentikasi.'
        ]);
    }

    /**
     * Poll the status of the QR code session.
     */
    public function pollSession(Request $request)
    {
        $request->validate([
            'session_id' => 'required|uuid',
            'token' => 'required|string|size:32',
        ]);

        $session = WebQrSession::where('session_id', $request->session_id)
            ->where('token', $request->token)
            ->first();

        if (!$session) {
            return response()->json(['error' => 'Sesi tidak valid.'], 404);
        }

        // Clean up old sessions (> 10 minutes)
        if ($session->created_at->addMinutes(10)->isPast()) {
            $session->status = 'expired';
            $session->save();
            return response()->json(['status' => 'expired', 'message' => 'Sesi kedaluwarsa. Silakan refresh QR Code.']);
        }

        if ($session->status === 'authenticated' && $session->kuskas_user_id) {
            $kuskasUserId = $session->kuskas_user_id;

            $user = User::find($kuskasUserId);

            if (!$user) {
                // If local user is missing
                $email = 'anon-' . substr($kuskasUserId, 0, 8) . '@kuskas.app';
                $user = User::create([
                    'id' => $kuskasUserId,
                    'full_name' => 'Kuskas User',
                    'email' => $email,
                ]);
            }

            // Log the user in
            Auth::login($user, true);

            // Clean up the session record so it can't be reused
            $session->delete();

            return response()->json([
                'status' => 'authenticated',
                'redirect' => route('dashboard'),
            ]);
        }

        return response()->json([
            'status' => $session->status, // pending
        ]);
    }
}
