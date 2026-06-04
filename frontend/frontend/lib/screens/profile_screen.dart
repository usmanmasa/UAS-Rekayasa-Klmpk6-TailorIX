import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Akun Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.name ?? 'Pengguna'),
              subtitle: const Text('Nama lengkap'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(user?.email ?? '-'),
              subtitle: const Text('Email'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(user?.phone ?? '-'),
              subtitle: const Text('Nomor HP'),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(user?.address ?? '-'),
              subtitle: const Text('Alamat'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ApiService.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
