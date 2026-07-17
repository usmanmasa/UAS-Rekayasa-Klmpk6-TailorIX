import 'package:flutter/material.dart';

/// Token warna TailorLX — tema "Atelier Modern".
/// Terinspirasi ruang kerja penjahit: indigo seperti kain denim,
/// emas seperti jarum pentul & gunting kuningan, kapur kain sebagai netral.
/// Sumber kebenaran tunggal untuk semua warna di aplikasi — jangan
/// hardcode warna lain di luar kelas ini, supaya tema tetap konsisten.
class AppColors {
  AppColors._();

  static const Color indigoDeep = Color(0xFF191F34);
  static const Color indigo = Color(0xFF273A5F);
  static const Color indigoLight = Color(0xFF4D6797);
  static const Color purple = Color(0xFF7E54B4);

  static const Color gold = Color(0xFFB6893E);
  static const Color goldLight = Color(0xFFD6BA72);
  static const Color goldPale = Color(0xFFF3E6C4);
  static const Color goldDeep = Color(0xFF8A6314);

  static const Color chalk = Color(0xFFF6F0E9);
  static const Color linen = Color(0xFFF0E7DC);
  static const Color linenDark = Color(0xFFD9CBB7);
  static const Color mist = Color(0xFFE4E8F2);
  static const Color pearl = Color(0xFFECEAE4);

  static const Color charcoal = Color(0xFF2B2F39);
  static const Color charcoalSoft = Color(0xFF6E7386);

  static const Color red = Color(0xFFBE5C4F);
  static const Color redPale = Color(0xFFF8E6E3);

  static const Color sage = Color(0xFF6B8A6E);
  static const Color sagePale = Color(0xFFE8EFE7);

  static const Color white = Color(0xFFFFFFFF);

  /// Warna & label untuk tiap status pesanan (lihat `Order.statusLabel`).
  /// Dipakai oleh [StatusBadge] supaya konsisten di semua layar.
  static const Map<String, StatusStyle> statusStyles = {
    'menunggu_konfirmasi': StatusStyle('Menunggu Konfirmasi', goldPale, goldDeep),
    'ditolak': StatusStyle('Pesanan Ditolak', redPale, red),
    'menunggu_pembayaran': StatusStyle('Menunggu Pembayaran', mist, indigo),
    'diproses': StatusStyle('Sedang Dikerjakan', sagePale, sage),
    'selesai': StatusStyle('Selesai', goldPale, goldDeep),
    'dibatalkan': StatusStyle('Dibatalkan', pearl, charcoalSoft),
  };
}

class StatusStyle {
  final String label;
  final Color background;
  final Color foreground;
  const StatusStyle(this.label, this.background, this.foreground);
}
