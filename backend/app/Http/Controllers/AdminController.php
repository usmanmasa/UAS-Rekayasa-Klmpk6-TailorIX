<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function summary(Request $request)
    {
        $customers = User::where('role', 'customer')->count();
        $tailors = User::where('role', 'tailor')->count();
        $admins = User::where('role', 'admin')->count();

        $orderCounts = Order::selectRaw('status, count(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        return response()->json([
            'status' => 'success',
            'message' => 'Ringkasan admin berhasil diambil.',
            'data' => [
                'summary' => [
                    'customers' => $customers,
                    'tailors' => $tailors,
                    'admins' => $admins,
                    'orders' => $orderCounts,
                ],
            ],
        ]);
    }

    public function users(Request $request)
    {
        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->filled('q')) {
            $keyword = '%' . $request->q . '%';
            $query->where(function ($sub) use ($keyword) {
                $sub->where('name', 'like', $keyword)
                    ->orWhere('email', 'like', $keyword)
                    ->orWhere('phone', 'like', $keyword)
                    ->orWhere('shop_name', 'like', $keyword);
            });
        }

        $users = $query->withCount(['orders', 'tailorOrders'])->paginate(20);

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar pengguna berhasil diambil.',
            'data' => [
                'users' => $users->items(),
                'meta' => [
                    'current_page' => $users->currentPage(),
                    'per_page' => $users->perPage(),
                    'total' => $users->total(),
                ],
            ],
        ]);
    }

    public function showUser(User $id)
    {
        $user = $id->load(['orders', 'tailorOrders', 'reviewsAsCustomer', 'reviewsAsTailor']);

        return response()->json([
            'status' => 'success',
            'message' => 'Detail pengguna berhasil diambil.',
            'data' => ['user' => $user],
        ]);
    }

    public function updateUser(Request $request, User $id)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255|unique:users,email,' . $id->id,
            'phone' => 'sometimes|string|max:30|unique:users,phone,' . $id->id,
            'address' => 'sometimes|string|max:500',
            'role' => 'sometimes|in:customer,tailor,admin',
            'shop_name' => 'sometimes|string|max:255',
            'location_lat' => 'sometimes|numeric',
            'location_lng' => 'sometimes|numeric',
            'specializations' => 'sometimes|array',
            'portfolio' => 'sometimes|array',
            'is_available' => 'sometimes|boolean',
            'is_verified' => 'sometimes|boolean',
        ]);

        $id->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Pengguna berhasil diperbarui.',
            'data' => ['user' => $id->fresh()],
        ]);
    }

    public function destroyUser(User $id)
    {
        $id->update([
            'is_verified' => false,
            'is_available' => false,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Pengguna berhasil dinonaktifkan.',
            'data' => null,
        ]);
    }

    public function tailors(Request $request)
    {
        $query = User::query()->where('role', 'tailor');

        if ($request->filled('q')) {
            $keyword = '%' . $request->q . '%';
            $query->where(function ($sub) use ($keyword) {
                $sub->where('name', 'like', $keyword)
                    ->orWhere('shop_name', 'like', $keyword)
                    ->orWhere('city', 'like', $keyword);
            });
        }

        $tailors = $query->withCount(['tailorOrders'])->paginate(20);

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar penjahit berhasil diambil.',
            'data' => [
                'tailors' => $tailors->items(),
                'meta' => [
                    'current_page' => $tailors->currentPage(),
                    'per_page' => $tailors->perPage(),
                    'total' => $tailors->total(),
                ],
            ],
        ]);
    }

    public function storeTailor(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
            'phone' => 'required|string|max:30|unique:users,phone',
            'shop_name' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'location_lat' => 'nullable|numeric',
            'location_lng' => 'nullable|numeric',
            'specializations' => 'nullable|array',
            'portfolio' => 'nullable|array',
        ]);

        $data['role'] = 'tailor';
        $data['is_verified'] = true;

        $user = User::create($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Penjahit berhasil dibuat.',
            'data' => ['tailor' => $user],
        ], 201);
    }

    public function updateTailor(Request $request, User $id)
    {
        if ($id->role !== 'tailor') {
            return response()->json([
                'status' => 'error',
                'message' => 'Pengguna bukan penjahit.',
                'data' => null,
            ], 422);
        }

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255|unique:users,email,' . $id->id,
            'phone' => 'sometimes|string|max:30|unique:users,phone,' . $id->id,
            'address' => 'sometimes|string|max:500',
            'shop_name' => 'sometimes|string|max:255',
            'location_lat' => 'sometimes|numeric',
            'location_lng' => 'sometimes|numeric',
            'specializations' => 'sometimes|array',
            'portfolio' => 'sometimes|array',
            'is_available' => 'sometimes|boolean',
            'is_verified' => 'sometimes|boolean',
        ]);

        $id->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Penjahit berhasil diperbarui.',
            'data' => ['tailor' => $id->fresh()],
        ]);
    }

    public function destroyTailor(User $id)
    {
        if ($id->role !== 'tailor') {
            return response()->json([
                'status' => 'error',
                'message' => 'Pengguna bukan penjahit.',
                'data' => null,
            ], 422);
        }

        $id->update(['is_available' => false, 'is_verified' => false]);

        return response()->json([
            'status' => 'success',
            'message' => 'Penjahit berhasil dinonaktifkan.',
            'data' => null,
        ]);
    }

    public function orders(Request $request)
    {
        $query = Order::with(['customer', 'tailor', 'photos', 'timelines']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }

        if ($request->filled('tailor_id')) {
            $query->where('tailor_id', $request->tailor_id);
        }

        if ($request->filled('search')) {
            $keyword = '%' . $request->search . '%';
            $query->where(function ($sub) use ($keyword) {
                $sub->whereHas('customer', fn($q) => $q->where('name', 'like', $keyword)->orWhere('email', 'like', $keyword))
                    ->orWhereHas('tailor', fn($q) => $q->where('name', 'like', $keyword)->orWhere('shop_name', 'like', $keyword));
            });
        }

        $orders = $query->paginate(20);

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar pesanan admin berhasil diambil.',
            'data' => [
                'orders' => $orders->items(),
                'meta' => [
                    'current_page' => $orders->currentPage(),
                    'per_page' => $orders->perPage(),
                    'total' => $orders->total(),
                ],
            ],
        ]);
    }
}
