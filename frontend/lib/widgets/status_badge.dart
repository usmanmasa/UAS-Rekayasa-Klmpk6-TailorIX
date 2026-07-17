import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pil status pesanan dengan warna konsisten di seluruh aplikasi
/// (Pelanggan & Mitra Penjahit), mengikuti status mentah dari backend
/// (`menunggu_konfirmasi`, `ditolak`, `menunggu_pembayaran`, `diproses`,
/// `selesai`, `dibatalkan` — lihat `Order.statusLabel`).
///
/// Pakai ini untuk MENGGANTI `Chip(label: Text(order.statusLabel))`,
/// supaya warnanya ikut menandakan tahapan, bukan cuma teks netral.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final style = AppColors.statusStyles[status];
    final label = style?.label ?? status;
    final bg = style?.background ?? AppColors.linen;
    final fg = style?.foreground ?? AppColors.charcoalSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: fontSize),
      ),
    );
  }
}
