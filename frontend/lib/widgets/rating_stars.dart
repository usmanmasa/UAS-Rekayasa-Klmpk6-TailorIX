import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tampilan rating bintang konsisten (mis. di kartu penjahit & ulasan).
/// [count] opsional menampilkan jumlah ulasan di sebelah angka rating.
class RatingStars extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;

  const RatingStars({super.key, required this.rating, this.count, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final full = rating.round().clamp(0, 5);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(
        5,
        (i) => Icon(
          i < full ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.gold,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        count != null ? '${rating.toStringAsFixed(1)} ($count ulasan)' : rating.toStringAsFixed(1),
        style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft),
      ),
    ]);
  }
}
