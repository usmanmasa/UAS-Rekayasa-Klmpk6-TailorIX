import 'package:flutter/material.dart';
import '../models/tailor.dart';
import '../services/api_service.dart';

const Color kNavy = Color(0xFF141E34);
const Color kGold = Color(0xFFF0B63B);
const Color kBgLight = Color(0xFFF6F7FB);
const Color kTextGrey = Color(0xFF9CA3AF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tailor>> _tailorsFuture;
  final Set<String> _favoriteIds = {};

  String _selectedLocation = 'Jakarta Selatan';

  static const List<String> _availableLocations = [
    'Jakarta Selatan',
    'Jakarta Pusat',
    'Jakarta Barat',
    'Jakarta Timur',
    'Jakarta Utara',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Bekasi',
    'Tangerang',
    'Depok',
  ];

  @override
  void initState() {
    super.initState();
    _tailorsFuture = ApiService.fetchTailors();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kNavy,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: kTextGrey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _availableLocations[index];
                    final isSelected = loc == _selectedLocation;
                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected ? kGold : kTextGrey,
                      ),
                      title: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 14,
                          color: kNavy,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: kGold, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedLocation = loc);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPromoCard(),
                  const SizedBox(height: 10),
                  _buildPromoDots(),
                  const SizedBox(height: 16),
                  _buildActiveOrder(),
                  const SizedBox(height: 22),
                  _buildSectionHeader('Penjahit Terdekat', onTap: () {
                    Navigator.pushNamed(context, '/maps');
                  }),
                  const SizedBox(height: 12),
                  _buildTailorList(),
                  const SizedBox(height: 22),
                  _buildSectionHeader('Kategori Jasa'),
                  const SizedBox(height: 12),
                  _buildCategoryGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(color: kNavy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _openLocationPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: kGold),
                      const SizedBox(width: 5),
                      Text(
                        _selectedLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: kGold),
                    ],
                  ),
                ),
              ),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kGold,
                    child: const Text(
                      'A',
                      style: TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF639922),
                        shape: BoxShape.circle,
                        border: Border.all(color: kNavy, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Selamat pagi',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 3),
          Row(
            children: const [
              Text(
                'Halo, Azis ',
                style: TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Text('👋', style: TextStyle(fontSize: 19)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kTextGrey, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cari penjahit atau layanan...',
                style: TextStyle(color: Color(0xFFB0B5C0), fontSize: 13),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.tune, color: kGold, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kNavy, Color(0xFF1E2D4D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer, color: kGold, size: 18),
              ),
              const SizedBox(height: 8),
              const Text('Promo Spesial',
                  style: TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Diskon 20%',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              const Text('Untuk pesanan pertama',
                  style: TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                Text('20%',
                    style: TextStyle(
                        fontSize: 18, color: kNavy, fontWeight: FontWeight.w600, height: 1)),
                Text('OFF',
                    style: TextStyle(fontSize: 10, color: kNavy, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 18, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(2))),
        Container(width: 5, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: const Color(0xFFD8DCE8), borderRadius: BorderRadius.circular(2))),
        Container(width: 5, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: const Color(0xFFD8DCE8), borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildActiveOrder() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/orders'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: kNavy.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.checkroom, color: kGold, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pesanan #TLX-001 sedang diproses',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kNavy)),
                  SizedBox(height: 2),
                  Text('Batik Tailor Bandung · Proses Permak',
                      style: TextStyle(fontSize: 11, color: kTextGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC9CDD6)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kNavy)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text('Lihat semua',
                    style: TextStyle(fontSize: 12, color: kGold, fontWeight: FontWeight.w500)),
                Icon(Icons.chevron_right, size: 16, color: kGold),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTailorList() {
    return FutureBuilder<List<Tailor>>(
      future: _tailorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 225, child: Center(child: CircularProgressIndicator(color: kGold)));
        }
        if (snapshot.hasError) {
          return SizedBox(
              height: 100,
              child: Center(child: Text('Gagal memuat data: ${snapshot.error}')));
        }
        final tailors = snapshot.data ?? [];
        if (tailors.isEmpty) {
          return const SizedBox(
              height: 100, child: Center(child: Text('Belum ada penjahit tersedia')));
        }
        return SizedBox(
          height: 225,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tailors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildTailorCard(tailors[index], index),
          ),
        );
      },
    );
  }

  Widget _buildTailorCard(Tailor tailor, int index) {
    final coverColors = [kNavy, const Color(0xFF534AB7), const Color(0xFF993C1D)];
    final coverColor = coverColors[index % coverColors.length];
    final isFav = _favoriteIds.contains(tailor.id);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tailor-detail', arguments: tailor),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: kNavy.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              width: double.infinity,
              color: coverColor,
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tailor.isAvailable
                            ? const Color(0xFFEAF3DE)
                            : const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tailor.isAvailable ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: tailor.isAvailable
                              ? const Color(0xFF3B6D11)
                              : const Color(0xFF5F5E5A),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(tailor.id),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 13,
                          color: isFav ? kGold : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tailor.shopName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: kTextGrey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          tailor.city,
                          style: const TextStyle(fontSize: 11, color: kTextGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 22,
                    child: Row(
                      children: tailor.specializations.take(2).map((s) {
                        return Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kBgLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F2F6), width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 11, color: kGold),
                            const SizedBox(width: 3),
                            Text('${tailor.rating}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500, color: kNavy)),
                            const SizedBox(width: 3),
                            Text('(${tailor.reviewsCount})',
                                style: const TextStyle(fontSize: 11, color: kTextGrey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${(tailor.estimatedPrice / 1000).toStringAsFixed(0)}rb',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w500, color: kNavy),
                            ),
                            const Text('mulai dari',
                                style: TextStyle(fontSize: 9, color: kTextGrey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'title': 'Ubah Ukuran', 'sub': 'Permak baju & celana', 'icon': Icons.open_in_full, 'color': kNavy, 'bg': kNavy.withValues(alpha: 0.06)},
      {'title': 'Ritsleting', 'sub': 'Ganti & perbaikan', 'icon': Icons.build_outlined, 'color': const Color(0xFF639922), 'bg': const Color(0xFF639922).withValues(alpha: 0.1)},
      {'title': 'Sulam', 'sub': 'Hiasan & bordir', 'icon': Icons.auto_awesome, 'color': const Color(0xFF534AB7), 'bg': const Color(0xFF534AB7).withValues(alpha: 0.1)},
      {'title': 'Tambal', 'sub': 'Perbaikan kain', 'icon': Icons.add_circle_outline, 'color': const Color(0xFFD85A30), 'bg': const Color(0xFFD85A30).withValues(alpha: 0.1)},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: categories.map((cat) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cat['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat['title'] as String,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: kNavy)),
                    const SizedBox(height: 1),
                    Text(cat['sub'] as String,
                        style: const TextStyle(fontSize: 10, color: kTextGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}