import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import 'customer_waiting_screen.dart';
import 'tailor_order_confirmation_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  static const _statusSteps = [
    'waiting_confirmation',
    'confirmed',
    'accepted',
    'process',
    'ready_for_pickup',
    'completed',
  ];

  static const _stepLabels = {
    'waiting_confirmation': 'Menunggu Konfirmasi',
    'confirmed': 'Dikonfirmasi',
    'accepted': 'Diterima Penjahit',
    'process': 'Proses Permak',
    'ready_for_pickup': 'Siap Diambil',
    'completed': 'Selesai',
  };

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isProcessing = false;

  Future<void> _acceptOrder(Order order) async {
    final finalPriceController = TextEditingController(text: order.estimatedPrice.toStringAsFixed(0));
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terima Pesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: finalPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Final'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Catatan Penjahit (opsional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Terima')),
          ],
        );
      },
    );

    if (result != true) return;

    setState(() => _isProcessing = true);
    try {
      final finalPrice = double.tryParse(finalPriceController.text.trim()) ?? order.estimatedPrice;
      final updatedOrder = await ApiService.acceptOrder(
        orderId: order.id,
        finalPrice: finalPrice,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateStatus(Order order, String statusLabel, String statusCode) async {
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah status menjadi $statusLabel'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        );
      },
    );

    if (result != true) return;
    setState(() => _isProcessing = true);
    try {
      final updatedOrder = await ApiService.updateOrderStatus(
        orderId: order.id,
        status: statusCode,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectOrder(Order order) async {
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Pesanan'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Catatan penolakan (opsional)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tolak')),
          ],
        );
      },
    );

    if (result != true) return;
    setState(() => _isProcessing = true);
    try {
      final updatedOrder = await ApiService.rejectOrder(
        orderId: order.id,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final currentIndex = OrderDetailScreen._statusSteps.indexOf(order.status);
    final isTailor = ApiService.currentUser?.role == 'tailor';

    if (order.status == 'waiting_confirmation') {
      if (isTailor) {
        return TailorOrderConfirmationScreen(order: order);
      }
      return CustomerWaitingScreen(order: order);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.tailor.shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: ${OrderDetailScreen._stepLabels[order.status] ?? order.statusLabel}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Kategori: ${order.category}'),
            Text('Deadline: ${order.deadline.day}/${order.deadline.month}/${order.deadline.year}'),
            Text('Mode Pengiriman: ${order.deliveryMode}'),
            const SizedBox(height: 16),
            if (order.photos.isNotEmpty) ...[
              const Text('Foto Pesanan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photoUrl = order.photos[index];
                    final imageUrl = photoUrl.startsWith('http') ? photoUrl : '${ApiService.baseUrl.replaceFirst('/api/v1', '')}/storage/$photoUrl';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order.description),
            const SizedBox(height: 16),
            Text('Estimasi Harga: ${order.estimatedPriceLabel}'),
            Text('Harga Final: Rp ${order.finalPrice > 0 ? order.finalPrice.toStringAsFixed(0) : order.estimatedPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            if (order.status == 'waiting_confirmation')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pesanan sedang menunggu konfirmasi penjahit. Silakan tunggu atau hubungi penjahit Anda jika perlu.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            if (order.status == 'confirmed')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pesanan telah dikonfirmasi oleh pelanggan. Tunggu penjahit menyelesaikan proses berikutnya.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            const Text('Timeline Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (order.timelines.isEmpty) ...[
              const Text('Tidak ada timeline tersedia untuk pesanan ini.'),
              const SizedBox(height: 12),
            ] else ...order.timelines.map((timeline) {
              final timelineIndex = OrderDetailScreen._statusSteps.indexOf(timeline.status);
              final isActive = timelineIndex >= 0 ? timelineIndex <= currentIndex : true;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.blueAccent : Colors.grey.shade300,
                  child: Text(timelineIndex >= 0 ? '${timelineIndex + 1}' : '-'),
                ),
                title: Text(OrderDetailScreen._stepLabels[timeline.status] ?? timeline.statusLabel),
                subtitle: Text('${timeline.notes}\n${timeline.createdAt.day}/${timeline.createdAt.month}/${timeline.createdAt.year} ${timeline.createdAt.hour}:${timeline.createdAt.minute.toString().padLeft(2, '0')}'),
                isThreeLine: true,
              );
            }),
            const Spacer(),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (isTailor && order.status == 'waiting_confirmation')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptOrder(order),
                        child: const Text('Terima'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectOrder(order),
                        child: const Text('Tolak'),
                      ),
                    ),
                  ],
                ),
              if (isTailor && order.status == 'accepted')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateStatus(order, 'Proses Permak', 'proses_perm'),
                      child: const Text('Mulai Proses Permak'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _updateStatus(order, 'Siap Diambil', 'siap_diambil'),
                      child: const Text('Tandai Siap Diambil'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _updateStatus(order, 'Selesai', 'selesai'),
                      child: const Text('Tandai Selesai'),
                    ),
                  ],
                ),
              if (order.status == 'accepted' || order.status == 'process' || order.status == 'ready_for_pickup')
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/payment', arguments: order),
                  child: const Text('Bayar / Lihat Pembayaran'),
                ),
              if (order.status == 'waiting_confirmation' && !isTailor)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Penjahit Anda akan menerima atau menolak pesanan ini dalam beberapa saat.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              if (order.status == 'completed' && !isTailor)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/review', arguments: order),
                  child: const Text('Berikan Ulasan'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
