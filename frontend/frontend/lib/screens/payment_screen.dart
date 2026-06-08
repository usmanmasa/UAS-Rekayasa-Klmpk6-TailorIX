import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _transactionId;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final dpAmount = (order.estimatedPrice * 0.5).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan ${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Estimasi Harga: ${order.estimatedPriceLabel}'),
            const SizedBox(height: 8),
            Text('Jumlah DP: Rp $dpAmount'),
            const SizedBox(height: 8),
            const Text('Metode Pembayaran yang didukung:'),
            const SizedBox(height: 8),
            const Text('- Transfer Bank BCA, BNI, BRI, Mandiri'),
            const Text('- GoPay, OVO, DANA'),
            const Text('- Virtual Account'),
            const SizedBox(height: 24),
            if (_message != null) ...[
              Text(_message!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _completePayment(order, dpAmount),
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Bayar DP Sekarang'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: (_transactionId == null || _isProcessing)
                  ? null
                  : () => _simulateSuccess(order),
              child: const Text('Simulasikan Pembayaran Berhasil'),
            ),
            if (_transactionId != null) ...[
              const SizedBox(height: 12),
              Text('Transaksi: $_transactionId', style: TextStyle(color: Colors.grey[700])),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completePayment(Order order, int amount) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isProcessing = true;
      _message = null;
    });

    String? errorMessage;
    String? transactionId;
    try {
      final paymentData = await ApiService.createPayment(
        orderId: order.id,
        amount: amount,
        paymentMethod: 'bank_transfer',
        paymentType: 'down_payment',
      );
      transactionId = paymentData['transaction_id']?.toString();
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (errorMessage != null) {
      setState(() => _message = errorMessage);
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    setState(() => _transactionId = transactionId);
    messenger.showSnackBar(const SnackBar(content: Text('Pembayaran berhasil diproses. Tekan simulasi untuk menyelesaikan.')));
  }

  Future<void> _simulateSuccess(Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_transactionId == null) return;

    setState(() {
      _isProcessing = true;
      _message = null;
    });

    String? errorMessage;
    try {
      await ApiService.simulatePaymentSuccess(orderId: order.id, transactionId: _transactionId!);
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (errorMessage != null) {
      setState(() => _message = errorMessage);
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    messenger.showSnackBar(const SnackBar(content: Text('Pembayaran terverifikasi. Status pesanan diperbarui.')));
  }
}
