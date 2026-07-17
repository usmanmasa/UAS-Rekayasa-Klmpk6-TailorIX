import 'json_helpers.dart';

// Kategori permak (mis. "Permak Celana Panjang", "Ganti Resleting"), diambil
// dari `GET /categories` — sumbernya sama dengan tabel `permak_categories`
// di backend, dikelola oleh admin. Dipakai di dropdown kategori pada
// `OrderFormScreen` supaya daftar tidak lagi hardcoded di sisi Flutter.
class PermakCategory {
  final int id;
  final String name;
  final double basePrice;

  PermakCategory(
      {required this.id, required this.name, required this.basePrice});

  factory PermakCategory.fromJson(Map<String, dynamic> json) {
    return PermakCategory(
      id: json['id'],
      name: json['name'] ?? '',
      basePrice: parseDouble(json['base_price']) ?? 0,
    );
  }
}
