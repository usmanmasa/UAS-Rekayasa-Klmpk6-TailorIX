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
            Text('Jumlah DP: Rp $dpAmount'),
            const SizedBox(height: 8),
            const Text('Metode Pembayaran yang didukung:'),
            const SizedBox(height: 8),
            const Text('- Transfer Bank BCA, BNI, BRI, Mandiri'),
            const Text('- GoPay, OVO, DANA'),
            const Text('- Virtual Account'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _completePayment(order, dpAmount),
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Bayar Sekarang'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulasi webhook Midtrans akan mengupdate status pesanan.'))),
              child: const Text('Simulasikan Pembayaran Berhasil'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completePayment(Order order, int amount) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);

    String? errorMessage;
    try {
      await ApiService.createPayment(orderId: order.id, amount: amount, method: 'bank_transfer');
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    messenger.showSnackBar(const SnackBar(content: Text('Pembayaran berhasil diproses.')));
  }
}
