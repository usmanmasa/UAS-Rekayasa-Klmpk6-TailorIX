import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class TailorOrderConfirmationScreen extends StatefulWidget {
  final Order order;

  const TailorOrderConfirmationScreen({super.key, required this.order});

  @override
  State<TailorOrderConfirmationScreen> createState() => _TailorOrderConfirmationScreenState();
}

class _TailorOrderConfirmationScreenState extends State<TailorOrderConfirmationScreen> {
  bool _isProcessing = false;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tailor_confirm_channel',
      'Tailor Confirmation',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iOSDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iOSDetails),
    );
  }

  Future<void> _acceptOrder() async {
    final finalPriceController = TextEditingController(text: widget.order.estimatedPrice.toStringAsFixed(0));
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
                decoration: const InputDecoration(labelText: 'Catatan penjahit (opsional)'),
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
      final finalPrice = double.tryParse(finalPriceController.text.trim()) ?? widget.order.estimatedPrice;
      final updatedOrder = await ApiService.acceptOrder(
        orderId: widget.order.id,
        finalPrice: finalPrice,
        notes: notesController.text.trim(),
      );

      await _showLocalNotification(
        title: 'Pesanan Diterima',
        body: 'Kamu telah menerima pesanan ${updatedOrder.id}.',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectOrder() async {
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Pesanan'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Alasan penolakan (opsional)'),
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
        orderId: widget.order.id,
        notes: notesController.text.trim(),
      );

      await _showLocalNotification(
        title: 'Pesanan Ditolak',
        body: 'Kamu telah menolak pesanan ${updatedOrder.id}.',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan Penjahit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan dari ${widget.order.customerName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Silakan tinjau detail pesanan dan pilih Terima atau Tolak.'),
            const SizedBox(height: 20),
            _buildInfoRow('Kategori', widget.order.category),
            _buildInfoRow('Deskripsi', widget.order.description),
            _buildInfoRow('Deadline', '${widget.order.deadline.day}/${widget.order.deadline.month}/${widget.order.deadline.year}'),
            _buildInfoRow('Mode Pengiriman', widget.order.deliveryMode),
            _buildInfoRow('Estimasi Harga', widget.order.estimatedPriceLabel),
            const SizedBox(height: 16),
            if (widget.order.photos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foto Referensi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.order.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final photoUrl = widget.order.photos[index];
                        final imageUrl = photoUrl.startsWith('http') ? photoUrl : '${ApiService.baseUrl.replaceFirst('/api/v1', '')}/storage/$photoUrl';
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const Spacer(),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptOrder,
                      child: const Text('Terima Pesanan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _rejectOrder,
                      child: const Text('Tolak Pesanan'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
