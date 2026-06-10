import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

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
      body: user == null
          ? const Center(child: Text('Silakan login terlebih dahulu.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.green.shade700,
                        child: Text(
                          user.photoUrl?.isNotEmpty == true ? '' : user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Status: ${user.role}', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Pesanan Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Belum ada pesanan aktif.', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 6),
                        Text('Silakan cek riwayat pesanan untuk melihat detail transaksi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _ProfileMenuTile(
                    icon: Icons.person,
                    title: 'Profil saya',
                    subtitle: 'Edit data profil dan foto',
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    icon: Icons.history,
                    title: 'Riwayat pesanan',
                    subtitle: 'Lihat order sebelumnya',
                    onTap: () => Navigator.pushNamed(context, '/order-history'),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.favorite_border,
                    title: 'Penjahit favorit',
                    subtitle: 'Daftar penjahit yang disimpan',
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    icon: Icons.notifications_none,
                    title: 'Notifikasi',
                    subtitle: 'Kelola pemberitahuan',
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    subtitle: 'Atur preferensi aplikasi',
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    icon: Icons.help_outline,
                    title: 'Bantuan & FAQ',
                    subtitle: 'Pertanyaan umum',
                    onTap: () {},
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
