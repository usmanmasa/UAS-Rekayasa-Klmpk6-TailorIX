import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../models/tailor_model.dart';
import 'api_client.dart';

/// Modul sisi Penjahit: kelola profil toko, dashboard ringkasan, serta
/// menerima/menolak pesanan dan memperbarui progres pengerjaan.
/// Endpoint-endpoint ini hanya bisa diakses oleh akun dengan role `penjahit`
/// (dilindungi middleware `role:penjahit` di backend).
class TailorService {
  final ApiClient api;
  TailorService(this.api);

  /// Lihat profil toko milik penjahit yang sedang login.
  Future<Tailor> getMyProfile() async {
    final res = await api.get('/tailor/profile');
    return Tailor.fromJson(res);
  }

  /// Lengkapi/perbarui profil toko (nama toko, deskripsi, alamat, lokasi).
  Future<Tailor> updateMyProfile({
    String? shopName,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (shopName != null) body['shop_name'] = shopName;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await api.put('/tailor/profile', body);
    return Tailor.fromJson(res);
  }

  /// Ringkasan dashboard: rating toko & jumlah pesanan per status.
  Future<TailorDashboard> getDashboard() async {
    final res = await api.get('/tailor/dashboard');
    return TailorDashboard.fromJson(res);
  }

  /// Langkah 13-14: Penjahit menerima atau menolak pesanan yang masuk.
  /// [finalPrice] opsional diisi saat menerima pesanan (`accept == true`) —
  /// jika kosong, backend akan memakai `estimated_price` sebagai fallback.
  Future<Order> respondToOrder({
    required int orderId,
    required bool accept,
    String? rejectionReason,
    double? finalPrice,
  }) async {
    final res = await api.post('/orders/$orderId/respond', {
      'decision': accept ? 'terima' : 'tolak',
      'rejection_reason': rejectionReason,
      'final_price': finalPrice,
    });
    return Order.fromJson(res);
  }

  /// Langkah 19-20: Penjahit memperbarui status pengerjaan (diproses/selesai).
  /// [photoPath] opsional: URL foto progres (hasil unggah lewat [UploadService])
  /// yang dilampirkan pada log status ini.
  Future<Order> updateProgress({
    required int orderId,
    required String status, // 'diproses' atau 'selesai'
    String? note,
    String? photoPath,
  }) async {
    final res = await api.post('/orders/$orderId/progress', {
      'status': status,
      'note': note,
      'photo_path': photoPath,
    });
    return Order.fromJson(res);
  }

  /// Upload one or more portfolio images for the authenticated tailor.
  /// Returns list of image URLs saved on server.
  Future<List<String>> uploadImages(List<String> filePaths) async {
    final uri = api.buildUri('/tailor/images');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(api.authHeaders);

    for (final p in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('images[]', p));
    }

    final streamed = await request.send().timeout(ApiClient.requestTimeout);
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (body['images'] as List?)?.map((e) => e as String).toList() ?? <String>[];
      return list;
    }

    throw ApiException(resp.statusCode, resp.body);
  }

  Future<void> deleteImage(int imageId) async {
    await api.delete('/tailor/images/$imageId');
  }
}

class TailorDashboard {
  final String shopName;
  final double ratingAvg;
  final int ratingCount;
  final Map<String, int> ordersByStatus;

  TailorDashboard({
    required this.shopName,
    required this.ratingAvg,
    required this.ratingCount,
    required this.ordersByStatus,
  });

  factory TailorDashboard.fromJson(Map<String, dynamic> json) {
    final raw = (json['orders_by_status'] as Map?) ?? {};
    return TailorDashboard(
      shopName: json['shop_name'] ?? '',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      ordersByStatus: raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
  }

  int get menungguKonfirmasi => ordersByStatus['menunggu_konfirmasi'] ?? 0;
  int get diproses => ordersByStatus['diproses'] ?? 0;
  int get selesai => ordersByStatus['selesai'] ?? 0;
  int get total => ordersByStatus.values.fold(0, (a, b) => a + b);
}
