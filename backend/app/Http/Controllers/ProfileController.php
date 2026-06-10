<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:30|unique:users,phone,' . $user->id,
            'address' => 'sometimes|string|max:500',
            'profile_photo_url' => 'sometimes|url|max:1000',
            'shop_name' => 'sometimes|string|max:255',
            'specializations' => 'sometimes|array',
            'portfolio' => 'sometimes|array',
            'location_lat' => 'sometimes|numeric',
            'location_lng' => 'sometimes|numeric',
            'device_token' => 'sometimes|string|max:1000',
        ]);

        $user->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Profil berhasil diperbarui.',
            'data' => ['user' => $user],
        ]);
    }

    public function updateDeviceToken(Request $request)
    {
        $request->validate([
            'device_token' => 'required|string|max:1000',
        ]);

        $user = $request->user();
        $user->update(['device_token' => $request->device_token]);

        return response()->json([
            'status' => 'success',
            'message' => 'Device token berhasil disimpan.',
            'data' => ['device_token' => $user->device_token],
        ]);
    }
}
