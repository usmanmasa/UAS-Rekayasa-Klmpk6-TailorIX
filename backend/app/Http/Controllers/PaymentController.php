<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Payment;
use App\Models\RefundRequest;
use App\Services\FcmService;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'required|string|max:100',
            'payment_type' => 'required|in:down_payment,final_payment',
        ]);

        $order = Order::findOrFail($request->order_id);

        $payment = Payment::create([
            'order_id' => $order->id,
            'amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'payment_type' => $request->payment_type,
            'status' => 'pending',
            'transaction_id' => 'trx_' . uniqid(),
            'snap_token' => 'mock_snap_token_' . uniqid(),
            'redirect_url' => url('/payment/redirect/' . uniqid()),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Transaksi pembayaran berhasil dibuat.',
            'data' => ['payment' => $payment],
        ], 201);
    }

    public function show(Payment $id)
    {
        $user = request()->user();

        if ($user->id !== $id->order->customer_id && $user->id !== $id->order->tailor_id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Status pembayaran berhasil diambil.',
            'data' => ['payment' => $id],
        ]);
    }

    public function webhook(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|string',
            'status' => 'required|string',
            'order_id' => 'required|exists:orders,id',
        ]);

        $payment = Payment::where('order_id', $request->order_id)
            ->where('transaction_id', $request->transaction_id)
            ->first();

        if (! $payment) {
            return response()->json(['status' => 'error', 'message' => 'Pembayaran tidak ditemukan.'], 404);
        }

        $payment->update(['status' => $request->status]);

        if ($request->status === 'settlement') {
            $order = $payment->order;
            $order->update(['status' => 'confirmed']);
            $order->load(['customer', 'tailor']);

            if ($order->tailor && ! empty($order->tailor->device_token)) {
                $tokens = array_filter(array_map('trim', explode(',', $order->tailor->device_token)));
                FcmService::send(
                    $tokens,
                    'DP Terbayar',
                    "Pembayaran DP untuk pesanan {$order->id} telah berhasil.",
                    ['order_id' => $order->id],
                );
            }
        }

        return response()->json(['status' => 'success', 'message' => 'Webhook diproses.']);
    }

    public function refund(Request $request, Payment $id)
    {
        $request->validate(['reason' => 'required|string|max:500']);

        if ($id->status !== 'settlement') {
            return response()->json(['status' => 'error', 'message' => 'Refund hanya dapat diajukan untuk pembayaran yang sudah selesai.'], 422);
        }

        $refund = RefundRequest::create([
            'payment_id' => $id->id,
            'order_id' => $id->order_id,
            'reason' => $request->reason,
            'status' => 'pending',
        ]);

        return response()->json(['status' => 'success', 'message' => 'Permintaan refund berhasil dikirim.', 'data' => ['refund_status' => $refund->status]]);
    }
}
