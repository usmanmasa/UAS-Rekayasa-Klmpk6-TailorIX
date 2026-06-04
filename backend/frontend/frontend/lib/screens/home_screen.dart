import 'package:flutter/material.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';
import '../widgets/tailor_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tailor>> _tailorsFuture;

  @override
  void initState() {
    super.initState();
    _tailorsFuture = ApiService.fetchTailors();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade600, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withAlpha(46),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Pelanggan'}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Temukan penjahit terbaik di dekat Anda dengan cepat.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.indigo.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cari penjahit atau layanan...',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rekomendasi Penjahit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Tailor>>(
                future: _tailorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Gagal memuat penjahit: ${snapshot.error}'),
                    );
                  }
                  final tailors = snapshot.data ?? [];
                  if (tailors.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada penjahit yang tersedia.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tailors.length,
                    itemBuilder: (context, index) {
                      final tailor = tailors[index];
                      return TailorCard(
                        tailor: tailor,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/tailor-detail',
                          arguments: tailor,
                        ),
                      );
                    },
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
