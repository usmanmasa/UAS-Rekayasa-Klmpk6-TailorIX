import 'package:flutter/material.dart';

import '../models/tailor.dart';

const Color kPrimaryGreen = Color(0xFF1D9E75);

class TailorDetailScreen extends StatelessWidget {
  const TailorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tailor = ModalRoute.of(context)!.settings.arguments as Tailor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryGreen.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white24,
                            child: Text(tailor.name.isNotEmpty ? tailor.name[0] : '?', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(tailor.shopName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(tailor.city, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                          const SizedBox(width: 6),
                                          Text(tailor.isAvailable ? 'Buka' : 'Tutup', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.white, size: 14),
                                          const SizedBox(width: 6),
                                          Text('${tailor.rating.toStringAsFixed(1)} (${tailor.reviewsCount})', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatCard(title: tailor.distanceKm.toStringAsFixed(1), subtitle: 'km dari sini'),
                          _StatCard(title: '5+', subtitle: 'tahun pengalaman'),
                          _StatCard(title: '200+', subtitle: 'pesanan selesai'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Layanan tersedia', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tailor.specializations.map((s) => Chip(
                          label: Text(s, style: const TextStyle(color: kPrimaryGreen, fontSize: 12)),
                          backgroundColor: kPrimaryGreen.withValues(alpha: 0.1),
                          side: BorderSide(color: kPrimaryGreen.withValues(alpha: 0.3)),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text('Ulasan pelanggan', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: kPrimaryGreen, child: const Text('AR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Andi R.', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 3),
                                    Row(children: List.generate(5, (i) => Icon(i < 5 ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Jahitannya rapi dan hasilnya sesuai ekspektasi. Pengerjaan cepat juga!', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 220),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Back button
          Positioned(
            top: 12,
            left: 8,
            child: SafeArea(
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 4,
                ),
                icon: const Icon(Icons.arrow_back, color: kPrimaryGreen),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGreen.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                        side: const BorderSide(color: kPrimaryGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // TODO: open maps
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Arah'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      onPressed: tailor.isAvailable ? () => Navigator.pushNamed(context, '/order-form', arguments: tailor) : null,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Buat Pesanan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StatCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
