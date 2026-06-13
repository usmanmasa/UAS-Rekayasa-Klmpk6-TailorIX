import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Aktif', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).fetchOrders());
  }

  List<Order> _filterOrders(List<Order> orders) {
    switch (_selectedTab) {
      case 1:
        return orders.where((order) => order.status == 'completed').toList();
      case 2:
        return orders.where((order) => order.status == 'cancelled').toList();
      default:
        return orders.where((order) => order.status != 'completed' && order.status != 'cancelled').toList();
    }
  }

  Widget _buildTabButton(int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0B63B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _tabs[index],
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isReadyForPickup = order.status == 'ready_for_pickup';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8E2C9),
                  child: Text(
                    order.tailor.shopName.isNotEmpty ? order.tailor.shopName[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Color(0xFF141E34), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.tailor.shopName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(order.category, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isReadyForPickup ? const Color(0xFFE8F0FF) : const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(order.statusLabel, style: TextStyle(fontSize: 12, color: isReadyForPickup ? const Color(0xFF141E34) : Colors.grey.shade700, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.timelines.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.timelines.take(3).map((timeline) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF0B63B), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeline.statusLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${timeline.createdAt.day.toString().padLeft(2, '0')} ${timeline.createdAt.month}/${timeline.createdAt.year} ${timeline.createdAt.hour.toString().padLeft(2, '0')}:${timeline.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Rp ${order.finalPrice > 0 ? order.finalPrice.toStringAsFixed(0) : order.estimatedPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReadyForPickup ? const Color(0xFF141E34) : const Color(0xFFF0B63B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (isReadyForPickup) {
                      Navigator.pushNamed(context, '/order-detail', arguments: order);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur chat belum tersedia.')));
                    }
                  },
                  child: Text(isReadyForPickup ? 'Ambil' : 'Chat', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pesanan Saya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${_selectedTab == 0 ? '3 pesanan aktif' : _selectedTab == 1 ? 'Riwayat pesanan selesai' : 'Pesanan dibatalkan'}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  _tabs.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 10),
                    child: _buildTabButton(index),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ordersState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Gagal memuat pesanan: $error')),
                  data: (orders) {
                    final filtered = _filterOrders(orders);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('Tidak ada pesanan pada kategori ini.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(filtered[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
