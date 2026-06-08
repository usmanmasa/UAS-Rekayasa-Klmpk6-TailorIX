import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat datang, Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Nama: ${user?.name ?? '-'}'),
            Text('Email: ${user?.email ?? '-'}'),
            const SizedBox(height: 20),
            const Text('Ringkasan Sistem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Kelola pengguna'),
                subtitle: const Text('Lihat, edit, dan hapus akun.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur manajemen pengguna belum tersedia di demo.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Kelola pesanan'),
                subtitle: const Text('Tinjau semua pesanan yang masuk.'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin-orders');
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Pengaturan admin'),
                subtitle: const Text('Konfigurasi sistem dan izin.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan admin belum tersedia di demo.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
