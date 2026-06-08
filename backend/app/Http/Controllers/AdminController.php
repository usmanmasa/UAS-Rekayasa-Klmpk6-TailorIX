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
