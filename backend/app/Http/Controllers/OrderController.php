<?php

namespace App\Http\Controllers;

use App\Models\MlEstimation;
use App\Models\Order;
use App\Models\OrderPhoto;
use App\Models\OrderTimeline;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'tailor_id' => ['required', Rule::exists('users', 'id')->where('role', 'tailor')->where('is_verified', true)],
            'category' => 'required|string|max:100',
            'description' => 'required|string|max:500',
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'required|string',
            'deadline' => 'required|date|after_or_equal:today',
            'delivery_mode' => 'required|string',
        ]);

        $photos = $request->input('photos', []);
        $deliveryMode = $this->normalizeDeliveryMode($request->delivery_mode);
        if ($deliveryMode === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Mode pengiriman tidak valid.',
                'data' => null,
            ], 422);
        }

        $estimation = $this->estimateFromMl($photos, $request->category, $request->description);

        $order = Order::create([
            'customer_id' => $request->user()->id,
            'tailor_id' => $request->tailor_id,
            'category' => $request->category,
            'description' => $request->description,
            'deadline' => $request->deadline,
            'delivery_mode' => $deliveryMode,
            'status' => 'waiting_confirmation',
            'estimated_price_min' => $estimation['min_price'],
            'estimated_price_max' => $estimation['max_price'],
            'confidence' => $estimation['confidence'],
        ]);

        if (is_array($photos) && count($photos) > 0) {
            foreach ($photos as $photo) {
                $photoPath = $this->storeOrderPhoto($photo, $order->id);
                OrderPhoto::create(['order_id' => $order->id, 'path' => $photoPath]);
            }
        }

        MlEstimation::create([
            'order_id' => $order->id,
            'category' => $request->category,
            'description' => $request->description,
            'photos' => is_array($photos) ? $photos : [],
            'min_price' => $estimation['min_price'],
            'max_price' => $estimation['max_price'],
            'confidence' => $estimation['confidence'],
            'analysis' => $estimation['analysis'],
        ]);

        OrderTimeline::create(['order_id' => $order->id, 'status' => 'waiting_confirmation', 'notes' => 'Pesanan dibuat dan menunggu konfirmasi penjahit.']);

        return response()->json([
            'status' => 'success',
            'message' => 'Pesanan berhasil dibuat.',
            'data' => ['order' => $order, 'estimation' => $estimation],
        ], 201);
    }

    protected function storeOrderPhoto(string $photo, int $orderId): string
    {
        if (preg_match('/^data:image\/(\w+);base64,(.+)$/', $photo, $matches)) {
            $extension = strtolower($matches[1]);
            $base64Data = $matches[2];
            $imageData = base64_decode($base64Data);

            if ($imageData === false) {
                throw new \RuntimeException('Data foto tidak valid.');
            }

            $filename = sprintf('order_photos/order_%s_%s.%s', $orderId, uniqid(), $extension);
            Storage::disk('public')->put($filename, $imageData);

            return $filename;
        }

        return $photo;
    }

    public function index(Request $request)
    {
        $query = Order::query();

        if ($request->user()->isAdmin()) {
            // Admin can see all orders.
        } elseif ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->id);
        } else {
            $query->where('tailor_id', $request->user()->id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }

        if ($request->filled('tailor_id')) {
            $query->where('tailor_id', $request->tailor_id);
        }

        $orders = $query->with(['photos', 'customer', 'tailor'])->paginate(20);

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar pesanan berhasil diambil.',
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

    public function show(Order $id)
    {
        $user = request()->user();

        if (!$user->isAdmin() && $user->id !== $id->customer_id && $user->id !== $id->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        $order = $id->load(['photos', 'timelines', 'payments', 'review', 'customer', 'tailor']);

        return response()->json([
            'status' => 'success',
            'message' => 'Detail pesanan berhasil diambil.',
            'data' => ['order' => $order],
        ]);
    }

    public function confirm(Request $request, Order $id)
    {
        $request->validate(['agreed_price' => 'required|numeric|min:0']);

        if ($request->user()->id !== $id->customer_id || $id->status !== 'waiting_confirmation') {
            return response()->json(['status' => 'error', 'message' => 'Pesanan tidak dapat dikonfirmasi.', 'data' => null], 403);
        }

        $id->update(['agreed_price' => $request->agreed_price, 'status' => 'confirmed']);
        OrderTimeline::create(['order_id' => $id->id, 'status' => 'confirmed', 'notes' => 'Pelanggan mengonfirmasi harga.']);

        return response()->json(['status' => 'success', 'message' => 'Pesanan dikonfirmasi.', 'data' => ['order' => $id]]);
    }

    public function accept(Request $request, Order $id)
    {
        $request->validate([
            'final_price' => 'required|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($request->user()->id !== $id->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        if ($id->status !== 'waiting_confirmation' && $id->status !== 'confirmed') {
            return response()->json(['status' => 'error', 'message' => 'Pesanan tidak dapat diterima pada status ini.', 'data' => null], 403);
        }

        $finalPrice = $request->final_price;
        $notes = $request->notes;
        $maximumAllowed = $id->estimated_price_max * 1.2;

        if ($finalPrice > $maximumAllowed && empty($notes)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Jika harga final melebihi 20% dari estimasi maksimum, catatan wajib diisi.',
                'data' => null,
            ], 422);
        }

        $id->update([
            'final_price' => $finalPrice,
            'tailor_notes' => $notes,
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);

        OrderTimeline::create(['order_id' => $id->id, 'status' => 'accepted', 'notes' => 'Penjahit menerima pesanan.']);

        return response()->json(['status' => 'success', 'message' => 'Pesanan diterima.', 'data' => ['order' => $id]]);
    }

    public function reject(Request $request, Order $id)
    {
        $request->validate([
            'notes' => 'nullable|string|max:500',
        ]);

        if ($request->user()->id !== $id->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        if ($id->status !== 'waiting_confirmation' && $id->status !== 'confirmed') {
            return response()->json(['status' => 'error', 'message' => 'Pesanan tidak dapat ditolak pada status ini.', 'data' => null], 403);
        }

        $id->update([
            'status' => 'cancelled',
            'tailor_notes' => $request->notes,
        ]);

        OrderTimeline::create(['order_id' => $id->id, 'status' => 'cancelled', 'notes' => 'Penjahit menolak pesanan.']);

        return response()->json(['status' => 'success', 'message' => 'Pesanan ditolak.', 'data' => ['order' => $id]]);
    }

    public function updateStatus(Request $request, Order $id)
    {
        $request->validate([
            'status' => 'required|in:proses_perm,siap_diambil,selesai',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($request->user()->id !== $id->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        $statusMap = [
            'proses_perm' => 'process',
            'siap_diambil' => 'ready_for_pickup',
            'selesai' => 'completed',
        ];

        $newStatus = $statusMap[$request->status] ?? $id->status;
        $id->update(['status' => $newStatus]);
        OrderTimeline::create(['order_id' => $id->id, 'status' => $newStatus, 'notes' => $request->notes]);

        return response()->json(['status' => 'success', 'message' => 'Status pesanan diperbarui.', 'data' => ['order' => $id]]);
    }

    public function destroy(Order $id, Request $request)
    {
        if ($request->user()->id !== $id->customer_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        if (in_array($id->status, ['accepted', 'process', 'ready_for_pickup', 'completed'])) {
            return response()->json(['status' => 'error', 'message' => 'Pesanan tidak dapat dibatalkan pada tahap ini.', 'data' => null], 403);
        }

        $id->update(['status' => 'cancelled', 'cancelled_at' => now()]);
        OrderTimeline::create(['order_id' => $id->id, 'status' => 'cancelled', 'notes' => 'Pelanggan membatalkan pesanan.']);

        return response()->json(['status' => 'success', 'message' => 'Pesanan dibatalkan.', 'data' => null]);
    }

    private function estimateFromMl(array $photos, string $category, string $description): array
    {
        $normalizedCategory = Str::lower(trim($category));
        $base = match ($normalizedCategory) {
            'ubah ukuran' => 70000,
            'ganti ritsleting' => 50000,
            'ganti ritsleting' => 50000,
            'tambal' => 80000,
            'tambah' => 80000,
            'sulam' => 65000,
            default => 60000,
        };

        $min = $base * 0.9;
        $max = $base * 1.3;
        $confidence = 75 + min(count($photos) * 5, 20);

        return [
            'min_price' => round($min, 2),
            'max_price' => round($max, 2),
            'confidence' => round($confidence, 2),
            'analysis' => [
                'category' => $category,
                'note' => 'Estimasi dasar berdasarkan jenis layanan dan jumlah foto.',
            ],
        ];
    }

    private function normalizeDeliveryMode(string $deliveryMode): ?string
    {
        $normalized = Str::lower(trim($deliveryMode));

        return match ($normalized) {
            'antar ke toko', 'dropoff' => 'dropoff',
            'pickup oleh kurir mitra penjahit', 'pickup' => 'pickup',
            default => null,
        };
    }
}
