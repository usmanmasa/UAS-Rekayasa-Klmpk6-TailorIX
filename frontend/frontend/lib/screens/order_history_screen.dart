import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/order_tile.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat pesanan: ${snapshot.error}'));
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Center(child: Text('Belum ada pesanan.'));
            }
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderTile(
                  order: order,
                  onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
