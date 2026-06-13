import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/order.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _ordersCount = 0;
  int _favoritesCount = 0;
  int _reviewsCount = 0;
  Order? _activeOrder;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.fetchOrders();
      // API should return orders scoped to current user when authenticated as customer.
      _ordersCount = orders.length;

      // find active order (waiting_confirmation, confirmed, accepted, process)
      _activeOrder = null;
      for (final order in orders) {
        if (['waiting_confirmation', 'confirmed', 'accepted', 'process'].contains(order.status)) {
          _activeOrder = order;
          break;
        }
      }

      // favorites and reviews may not have dedicated endpoints; keep fallback 0
      _favoritesCount = 0;
      _reviewsCount = 0;
    } catch (_) {
      _ordersCount = 0;
      _favoritesCount = 0;
      _reviewsCount = 0;
      _activeOrder = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ApiService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(user),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 18),
            const Text('PESANAN AKTIF', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            _buildActiveOrderCard(),
            const SizedBox(height: 18),
            const Text('AKUN SAYA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildMenuTile(Icons.person, 'Data diri', 'Nama, nomor HP, alamat', onTap: () {}),
            _buildMenuTile(Icons.location_on, 'Alamat pengiriman', 'Kelola alamat pickup', onTap: () {}),
            const SizedBox(height: 12),
            const Text('AKTIVITAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildMenuTile(Icons.shopping_bag, 'Pesanan saya', 'Pantau status jahitan', badge: _ordersCount > 0 ? _ordersCount : 0, onTap: () => Navigator.pushNamed(context, '/order-history')),
            _buildMenuTile(Icons.history, 'Riwayat pesanan', 'Semua transaksi lalu', onTap: () => Navigator.pushNamed(context, '/order-history')),
            _buildMenuTile(Icons.favorite_border, 'Penjahit favorit', '5 penjahit disimpan', onTap: () {}),
            _buildMenuTile(Icons.rate_review, 'Ulasan saya', 'Review yang pernah ditulis', onTap: () {}),
            const SizedBox(height: 12),
            const Text('LAINNYA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildMenuTile(Icons.notifications_none, 'Notifikasi', 'Atur pemberitahuan', badge: 1, onTap: () {}),
            _buildMenuTile(Icons.settings, 'Pengaturan', 'Preferensi aplikasi', onTap: () {}),
            _buildMenuTile(Icons.help_outline, 'Bantuan & FAQ', 'Pertanyaan umum', onTap: () {}),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () {
                ApiService.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.blueGrey.shade700,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 6),
                Text(user.phone.isNotEmpty ? user.phone : '-', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(user.role[0].toUpperCase() + user.role.substring(1), style: const TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(_ordersCount, 'Pesanan'),
        const SizedBox(width: 8),
        _buildStatItem(_favoritesCount, 'Favorit'),
        const SizedBox(width: 8),
        _buildStatItem(_reviewsCount, 'Ulasan'),
      ],
    );
  }

  Widget _buildStatItem(int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeOrder == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Belum ada pesanan aktif', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Silakan cek riwayat pesanan untuk melihat status pesanan Anda.', style: TextStyle(color: Colors.black54)),
        ]),
      );
    }

    final order = _activeOrder!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 8, height: 48, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Deadline ${order.deadline.day}/${order.deadline.month}/${order.deadline.year}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(16)),
              child: Text(order.status[0].toUpperCase() + order.status.substring(1), style: const TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, {int? badge, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: Icon(icon, color: Colors.black87, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null && badge > 0)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)), child: Text(badge.toString(), style: const TextStyle(color: Colors.red))),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right),
      ]),
      onTap: onTap,
    );
  }
}
