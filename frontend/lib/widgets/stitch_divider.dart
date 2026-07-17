import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Elemen tanda tangan visual TailorLX: garis jahitan jelujur (basting
/// stitch) putus-putus berwarna emas, dipakai sebagai pembatas antar
/// bagian (mis. di profil penjahit & lacak pesanan) — menggantikan
/// `Divider()` polos agar terasa "dijahit", bukan sekadar garis sistem.
class StitchDivider extends StatelessWidget {
  final double verticalMargin;
  const StitchDivider({super.key, this.verticalMargin = 14});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalMargin),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _StitchPainter(),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withAlpha(179)
      ..strokeWidth = 1.4;
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Garis vertikal jelujur untuk linimasa status pesanan
/// (lihat penggunaannya di `order_tracking_screen.dart`).
class StitchTimelineConnector extends StatelessWidget {
  final double height;
  const StitchTimelineConnector({super.key, this.height = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(painter: _VerticalStitchPainter()),
    );
  }
}

class _VerticalStitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.linenDark
      ..strokeWidth = 2;
    const dashHeight = 5.0;
    const dashSpace = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
