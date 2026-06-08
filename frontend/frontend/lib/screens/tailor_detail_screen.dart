import 'package:flutter/material.dart';

import '../models/tailor.dart';

class TailorDetailScreen extends StatelessWidget {
  const TailorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tailor = ModalRoute.of(context)!.settings.arguments as Tailor;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penjahit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 34, child: Text(tailor.name[0], style: const TextStyle(fontSize: 24))),
              title: Text(tailor.shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('${tailor.city} • ${tailor.distanceKm.toStringAsFixed(1)} km'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tailor.isAvailable ? Icons.check_circle : Icons.remove_circle, color: tailor.isAvailable ? Colors.green : Colors.grey),
                  const SizedBox(height: 4),
                  Text(tailor.isAvailable ? 'Tersedia' : 'Sibuk'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        tailor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text('(${tailor.reviewsCount} ulasan)', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${tailor.city} • ${tailor.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(tailor.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tailor.specializations.map((item) => Chip(label: Text(item))).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Portofolio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: tailor.portfolio.map((item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image),
                title: Text(item),
              )).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: tailor.isAvailable ? () => Navigator.pushNamed(context, '/order-form', arguments: tailor) : null,
              child: const Text('Pesan Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
