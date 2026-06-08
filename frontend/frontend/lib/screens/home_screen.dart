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
  final List<String> _categories = [
    'Ubah Ukuran',
    'Tambal',
    'Ritsleting',
    'Sulam',
  ];
  String _selectedCategory = 'Ubah Ukuran';

  @override
  void initState() {
    super.initState();
    _tailorsFuture = ApiService.fetchTailors();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FCF9),
      appBar: AppBar(
        title: const Text('Beranda'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF239B56), Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?.name ?? 'Rina'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Mau permak apa hari ini?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'R',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF239B56)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cari penjahit atau layanan...',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                ),
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
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF239B56)
                              : Colors.green.shade100,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF239B56)
                              : Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Penjahit Terdekat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Tailor>>(
                future: _tailorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF239B56),
                      ),
                    );
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
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: tailors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
