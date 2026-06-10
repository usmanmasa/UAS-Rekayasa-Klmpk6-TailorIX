import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class CustomerWaitingScreen extends StatefulWidget {
  final Order order;

  const CustomerWaitingScreen({super.key, required this.order});

  @override
  State<CustomerWaitingScreen> createState() => _CustomerWaitingScreenState();
}

class _CustomerWaitingScreenState extends State<CustomerWaitingScreen> {
  late Order _order;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _lastStatus = _order.status;
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkOrderStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkOrderStatus() async {
    await _refreshOrder();
    if (!mounted) return;
    if (_lastStatus == 'waiting_confirmation' && _order.status != 'waiting_confirmation') {
      final title = _order.status == 'accepted' ? 'Pesanan Diterima' : 'Pesanan Dibatalkan';
      final message = _order.status == 'accepted'
          ? 'Penjahit telah menerima pesanan kamu.'
          : 'Penjahit menolak pesanan kamu. Silakan cek detail pesanan.';
      _lastStatus = _order.status;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: _order);
    }
  }

  Future<void> _refreshOrder() async {
    setState(() => _isRefreshing = true);
    try {
      final updatedOrder = await ApiService.fetchOrderDetail(_order.id);
      if (!mounted) return;
      setState(() => _order = updatedOrder);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Konfirmasi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pesanan kamu sedang menunggu konfirmasi dari penjahit.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kami akan memberitahu kamu setelah penjahit merespons.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Detail Pesanan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Penjahit', _order.tailor.shopName),
            _buildInfoRow('Kategori', _order.category),
            _buildInfoRow('Deadline', '${_order.deadline.day}/${_order.deadline.month}/${_order.deadline.year}'),
            _buildInfoRow('Estimasi Harga', _order.estimatedPriceLabel),
            const Spacer(),
            if (_isRefreshing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _refreshOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Perbarui Status'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
