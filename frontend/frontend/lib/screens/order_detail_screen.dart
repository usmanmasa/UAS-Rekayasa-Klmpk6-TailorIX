import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final timeline = [
      'Menunggu Konfirmasi',
      'Dikonfirmasi',
      'Proses Permak',
      'Siap Diambil',
      'Selesai',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.tailor.shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: ${order.status}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Kategori: ${order.category}'),
            Text('Deadline: ${order.deadline.day}/${order.deadline.month}/${order.deadline.year}'),
            Text('Mode Pengiriman: ${order.deliveryMode}'),
            const SizedBox(height: 16),
            Text('Deskripsi:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order.description),
            const SizedBox(height: 16),
            Text('Estimasi Harga: Rp ${order.estimatedPrice.toStringAsFixed(0)}'),
            Text('Harga Final: Rp ${order.finalPrice > 0 ? order.finalPrice.toStringAsFixed(0) : order.estimatedPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            const Text('Timeline Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...timeline.map((step) {
              final isActive = timeline.indexOf(step) <= timeline.indexOf(order.status);
              return ListTile(
                leading: CircleAvatar(backgroundColor: isActive ? Colors.blueAccent : Colors.grey.shade300, child: Text('${timeline.indexOf(step) + 1}')),
                title: Text(step),
                subtitle: Text(isActive ? 'Telah dilalui' : 'Menunggu'),
              );
            }),
            const Spacer(),
            if (order.status != 'Selesai')
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/payment', arguments: order),
                child: const Text('Bayar / Lihat Pembayaran'),
              ),
          ],
        ),
      ),
    );
  }
}
