<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string $roles)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Autentikasi dibutuhkan.',
                'data' => null,
            ], 401);
        }

        $allowedRoles = array_map('trim', explode(',', $roles));
        if (!in_array($user->role, $allowedRoles, true)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Akses ditolak untuk peran ini.',
                'data' => null,
            ], 403);
        }

        return $next($request);
    }
}
