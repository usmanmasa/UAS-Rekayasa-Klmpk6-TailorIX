import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/order_tile.dart';

class TailorDashboardScreen extends StatefulWidget {
  const TailorDashboardScreen({super.key});

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.fetchOrders();
  }

  int _countByStatus(List<Order> orders, String status) {
    return orders.where((order) => order.status == status).length;
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Penjahit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
            }
            final orders = snapshot.data ?? [];
            final waitingCount = _countByStatus(orders, 'waiting_confirmation');
            final acceptedCount = _countByStatus(orders, 'accepted');
            final processCount = _countByStatus(orders, 'process');
            final readyCount = _countByStatus(orders, 'ready_for_pickup');
            final completedCount = _countByStatus(orders, 'completed');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusCard('Menunggu', waitingCount, Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatusCard('Diterima', acceptedCount, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusCard('Proses', processCount, Colors.purple),
                      const SizedBox(width: 12),
                      _buildStatusCard('Siap Ambil', readyCount, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard('Selesai', completedCount, Colors.teal),
                  const SizedBox(height: 24),
                  const Text('Fungsi Utama Tailor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('• Autentikasi & Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Edit profil, lihat peran, dan logout.'),
                          SizedBox(height: 16),
                          Text('• Pemesanan & Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Lihat pesanan masuk, terima/tolak, dan update status pesanan.'),
                          SizedBox(height: 16),
                          Text('• Estimasi Harga Otomatis', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Tampilkan estimasi ML dan validasi harga final saat menerima pesanan.'),
                          SizedBox(height: 16),
                          Text('• Ulasan & Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Review disampaikan setelah pesanan selesai; penjahit dapat melihat riwayat pesanan selesai.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Pesanan Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (orders.isEmpty)
                    const Center(child: Text('Belum ada pesanan.'))
                  else ...[
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: orders.length > 3 ? 3 : orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return OrderTile(
                          order: order,
                          onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/order-history'),
                      child: const Text('Lihat Semua Pesanan'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
