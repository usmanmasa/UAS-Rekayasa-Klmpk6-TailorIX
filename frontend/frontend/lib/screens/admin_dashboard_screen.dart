import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = ApiService.fetchAdminSummary();
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

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
            Text('Selamat datang, ${user?.name ?? 'Admin'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Email: ${user?.email ?? '-'}'),
            const SizedBox(height: 24),
            const Text('Ringkasan Sistem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Gagal memuat ringkasan.'));
                }
                final summary = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard('Pelangan', summary['customers'].toString(), Colors.blue),
                        const SizedBox(width: 12),
                        _buildStatCard('Penjahit', summary['tailors'].toString(), Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard('Admin', summary['admins'].toString(), Colors.indigo),
                        const SizedBox(width: 12),
                        _buildStatCard('Pesanan', summary['order_count'].toString(), Colors.orange),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Manajemen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Kelola Pengguna'),
                subtitle: const Text('Kelola akun pelanggan, penjahit, dan admin.'),
                onTap: () => Navigator.pushNamed(context, '/admin-users'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Kelola Pesanan'),
                subtitle: const Text('Pantau aktivitas pesanan dan laporan.'),
                onTap: () => Navigator.pushNamed(context, '/admin-orders'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Laporan Aktivitas'),
                subtitle: const Text('Analisis volume pesanan dan aktivitas platform.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan aktivitas tersedia di ringkasan sistem.')),
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
