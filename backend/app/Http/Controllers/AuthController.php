<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'phone' => 'required|string|max:30|unique:users',
            'address' => 'sometimes|nullable|string|max:255',
            'shop_name' => 'sometimes|nullable|string|max:255',
            'role' => 'required|in:customer,tailor,admin',
            'terms_accepted' => 'accepted',
        ]);

        $userData = [
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['phone'],
            'role' => $data['role'],
            'address' => $data['address'] ?? null,
            'shop_name' => $data['shop_name'] ?? null,
            'is_verified' => $data['role'] === 'customer',
            'terms_accepted' => true,
            'terms_accepted_at' => now(),
        ];

        if ($data['role'] === 'admin') {
            $userData['is_verified'] = true;
        }

        $user = User::create($userData);

        event(new Registered($user));

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Registrasi berhasil.',
            'data' => [
                'user' => $user,
                'token' => $token,
            ],
        ], 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt($credentials)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Kredensial tidak valid.',
                'data' => null,
            ], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Login berhasil.',
            'data' => [
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Logout berhasil.',
            'data' => null,
        ]);
    }

    public function refresh(Request $request)
    {
        $user = $request->user();
        $user->currentAccessToken()->delete();
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Token diperbarui.',
            'data' => [
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $status = Password::sendResetLink($request->only('email'));

        return response()->json([
            'status' => $status === Password::RESET_LINK_SENT ? 'success' : 'error',
            'message' => $status === Password::RESET_LINK_SENT ? 'Tautan reset password telah dikirim.' : 'Email tidak ditemukan.',
            'data' => null,
        ], $status === Password::RESET_LINK_SENT ? 200 : 404);
    }
}
