import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tampilan seragam saat sebuah daftar kosong (favorit, pesanan, notifikasi,
/// dst.) — mengajak pengguna bertindak, bukan sekadar "tidak ada data".
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const EmptyState({super.key, required this.emoji, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.charcoalSoft, height: 1.6)),
        ]),
      ),
    );
  }
}
