import 'package:flutter/material.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';

const Color kPrimaryGreen = Color(0xFF1D9E75);
const Color kBackground = Color(0xFFF0F8F5);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kSectionText = Color(0xFF4A5568);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tailor>> _tailorsFuture;
  final List<String> _categories = [
    'Semua',
    'Ubah Ukuran',
    'Tambal',
    'Ritsleting',
    'Sulam',
  ];
  String _selectedCategory = 'Semua';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tailorsFuture = ApiService.fetchTailors();
  }

  Widget _buildSectionTitle(String title, {String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1B3D2D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (actionLabel != null)
          Text(
            actionLabel,
            style: const TextStyle(
              color: kPrimaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildTopCard() {
    final userName = ApiService.currentUser?.name ?? 'Azis';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryGreen, Color(0xFF259E6D)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bandung, Jawa Barat',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mau permak apa hari ini?',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                offset: const Offset(0, 10),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'orders':
                      Navigator.pushNamed(context, '/order-history');
                      break;
                    case 'favorites':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'notifications':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'help':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'logout':
                      ApiService.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'header',
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(color: Color(0xFF1B3D2D), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(ApiService.currentUser?.email ?? '-', style: const TextStyle(color: Color(0xFF7A8A95), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(ApiService.currentUser?.role.toUpperCase() ?? '-', style: const TextStyle(color: kPrimaryGreen, fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(value: 'profile', child: Text('Profil saya', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuItem<String>(value: 'orders', child: Text('Riwayat pesanan', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuItem<String>(value: 'favorites', child: Text('Penjahit favorit', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuItem<String>(value: 'notifications', child: Text('Notifikasi', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuItem<String>(value: 'settings', child: Text('Pengaturan', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuItem<String>(value: 'help', child: Text('Bantuan & FAQ', style: TextStyle(color: Color(0xFF1B3D2D)))),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: const Text(
                        'Keluar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ];
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: kPrimaryGreen,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: kPrimaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cari penjahit atau layanan...',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 18),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryGreen : Color(0xFFE8F5F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF4E5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: kPrimaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Diskon 20% untuk pelanggan baru!',
                  style: TextStyle(
                    color: Color(0xFF0F2A1D),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Gunakan kode: TAILORIX20',
                  style: TextStyle(
                    color: Color(0xFF1F4F37),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.copy, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNearestTailorCard(Tailor tailor) {
    final statusColor = tailor.isAvailable ? kPrimaryGreen : Colors.grey.shade500;
    final specializationText = tailor.specializations.isNotEmpty
        ? tailor.specializations.take(3).join(' · ')
        : tailor.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.pushNamed(context, '/tailor-detail', arguments: tailor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5F0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          tailor.shopName.isNotEmpty ? tailor.shopName[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            color: kPrimaryGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tailor.shopName,
                                  style: const TextStyle(
                                    color: Color(0xFF1B3D2D),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tailor.isAvailable ? 'Buka' : 'Tutup',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            specializationText,
                            style: const TextStyle(color: Color(0xFF7A8A95), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.place, size: 14, color: kPrimaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            '${tailor.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(color: kSectionText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFB703)),
                          const SizedBox(width: 6),
                          Text(
                            tailor.rating.toStringAsFixed(1),
                            style: const TextStyle(color: kSectionText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rp 80.000/item',
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: kSectionText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: const Text('TailoriX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Tailor>>(
          future: _tailorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimaryGreen),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat penjahit: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            final tailors = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopCard(),
                  const SizedBox(height: 16),
                  _buildPromoCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Penjahit terdekat', actionLabel: 'Lihat semua'),
                  const SizedBox(height: 12),
                  ...tailors.take(3).map(_buildNearestTailorCard),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Layanan populer'),
                  const SizedBox(height: 14),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    childAspectRatio: 1.35,
                    children: const [
                      _ServiceGridItem(label: 'Ubah ukuran', subtitle: '12 penjahit'),
                      _ServiceGridItem(label: 'Tambal', subtitle: '8 penjahit'),
                      _ServiceGridItem(label: 'Ritsleting', subtitle: '6 penjahit'),
                      _ServiceGridItem(label: 'Sulam', subtitle: '5 penjahit'),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushNamed(context, '/profile');
            return;
          }
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifikasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ServiceGridItem extends StatelessWidget {
  final String label;
  final String subtitle;

  const _ServiceGridItem({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_box_outline_blank, color: kPrimaryGreen, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B3D2D),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: const TextStyle(color: kSectionText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


