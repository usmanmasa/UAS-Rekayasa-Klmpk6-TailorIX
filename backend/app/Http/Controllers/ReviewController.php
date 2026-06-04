<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ReviewController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:300',
            'photos' => 'nullable|array|max:3',
            'photos.*' => 'string',
        ]);

        $order = Order::findOrFail($request->order_id);

        if ($order->customer_id !== $request->user()->id || $order->status !== 'completed') {
            return response()->json(['status' => 'error', 'message' => 'Ulasan hanya dapat dibuat untuk pesanan selesai oleh pelanggan yang sesuai.', 'data' => null], 403);
        }

        $review = Review::create([
            'order_id' => $order->id,
            'customer_id' => $request->user()->id,
            'tailor_id' => $order->tailor_id,
            'rating' => $request->rating,
            'comment' => $request->comment,
            'photos' => $request->photos,
            'status' => 'visible',
        ]);

        $tailor = $order->tailor;
        $tailor->rating_count += 1;
        $tailor->rating = ($tailor->rating * ($tailor->rating_count - 1) + $review->rating) / $tailor->rating_count;
        $tailor->save();

        return response()->json(['status' => 'success', 'message' => 'Ulasan berhasil ditambahkan.', 'data' => ['review' => $review]], 201);
    }

    public function show(Review $id)
    {
        return response()->json(['status' => 'success', 'message' => 'Detail ulasan berhasil diambil.', 'data' => ['review' => $id]]);
    }

    public function update(Request $request, Review $id)
    {
        if ($id->customer_id !== $request->user()->id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        if ($id->created_at->diffInDays(now()) > 7) {
            return response()->json(['status' => 'error', 'message' => 'Ulasan hanya dapat diedit dalam 7 hari.', 'data' => null], 422);
        }

        $request->validate([
            'rating' => 'sometimes|integer|min:1|max:5',
            'comment' => 'sometimes|string|max:300',
        ]);

        $id->update($request->only('rating', 'comment'));

        return response()->json(['status' => 'success', 'message' => 'Ulasan berhasil diperbarui.', 'data' => ['review' => $id]]);
    }

    public function reply(Request $request, Review $id)
    {
        if ($request->user()->id !== $id->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        $request->validate(['reply_text' => 'required|string|max:200']);

        $id->update(['reply_text' => $request->reply_text]);

        return response()->json(['status' => 'success', 'message' => 'Balasan ulasan berhasil disimpan.', 'data' => ['review' => $id]], 201);
    }

    public function report(Request $request, Review $id)
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $id->update(['reported' => true, 'status' => 'hidden']);

        return response()->json(['status' => 'success', 'message' => 'Ulasan dilaporkan dan akan dimoderasi.', 'data' => null], 201);
    }
}
