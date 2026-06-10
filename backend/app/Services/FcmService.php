<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    public static function send(array $tokens, string $title, string $body, array $data = []): void
    {
        $tokens = array_values(array_filter(array_map('trim', $tokens)));
        if (empty($tokens)) {
            return;
        }

        $serverKey = config('services.fcm.server_key');
        if (empty($serverKey)) {
            Log::warning('FCM server key not configured. Notification skipped.', [
                'title' => $title,
                'body' => $body,
                'tokens' => $tokens,
            ]);
            return;
        }

        $payload = [
            'registration_ids' => $tokens,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $data,
        ];

        $response = Http::withHeaders([
            'Authorization' => 'key ' . $serverKey,
            'Content-Type' => 'application/json',
        ])->post('https://fcm.googleapis.com/fcm/send', $payload);

        if (! $response->successful()) {
            Log::error('FCM notification request failed.', [
                'status' => $response->status(),
                'body' => $response->body(),
                'tokens' => $tokens,
            ]);
        }
    }

    public static function sendToAdmin(string $title, string $body, array $data = []): void
    {
        $admins = \App\Models\User::where('role', 'admin')
            ->whereNotNull('device_token')
            ->pluck('device_token')
            ->toArray();

        $tokens = array_values(array_filter(array_map('trim', $admins)));
        if (empty($tokens)) {
            return;
        }

        self::send($tokens, $title, $body, $data);
    }
}
