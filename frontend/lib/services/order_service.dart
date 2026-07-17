import '../models/order_model.dart';
import '../models/pickup_slot_model.dart';
import '../models/tailor_model.dart';
import 'api_client.dart';

/// Setiap method merepresentasikan satu langkah pada Sequence Diagram
/// Pemesanan Jasa Permak.
class OrderService {
  final ApiClient api;
  OrderService(this.api);

  /// Langkah 2-3: Cari penjahit
  Future<List<Tailor>> searchTailors(
      {String? query, String? category, double? lat, double? lng}) async {
    final params = <String>[];
    if (query != null && query.isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(query)}');
    }
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeQueryComponent(category)}');
    }
    if (lat != null && lng != null) {
      params.add('lat=$lat&lng=$lng');
    }
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await api.get('/tailors$qs');
    final data = (res['data'] as List).map((e) => Tailor.fromJson(e)).toList();
    return data;
  }

  Future<List<Tailor>> getNearbyTailors() async {
    final res = await api.get('/tailors');
    final data = (res['data'] as List).map((e) => Tailor.fromJson(e)).toList();
    return data;
  }

  Future<List<Tailor>> recommendTailors() async {
    final res = await api.get('/tailors/recommendations');
    final data = (res as List).map((e) => Tailor.fromJson(e as Map<String, dynamic>)).toList();
    return data;
  }

  /// Langkah 4: Lihat profil penjahit
  Future<Tailor> getTailorProfile(int tailorId) async {
    final res = await api.get('/tailors/$tailorId');
    return Tailor.fromJson(res);
  }

  /// Daftar pesanan milik user yang sedang login (pelanggan: pesanannya sendiri,
  /// penjahit: pesanan yang masuk ke tokonya). Bisa difilter per status.
  Future<List<Order>> listOrders({List<String>? statuses}) async {
    final qs = statuses != null && statuses.isNotEmpty
        ? '?status=${statuses.join(',')}'
        : '';
    final res = await api.get('/orders$qs');
    final data = (res['data'] as List).map((e) => Order.fromJson(e)).toList();
    return data;
  }

  /// Langkah 7-10: Kirim detail permak, dapatkan estimasi harga dari ML Service
  Future<Map<String, dynamic>> getPriceEstimate({
    required int tailorId,
    required int categoryId,
    String? description,
    String? photoPath,
    required DateTime deadline,
    double? customerLatitude,
    double? customerLongitude,
  }) async {
    final res = await api.post('/orders/estimate', {
      'tailor_id': tailorId,
      'category_id': categoryId,
      'description': description,
      'photo_path': photoPath,
      'deadline': deadline.toIso8601String().split('T').first,
      if (customerLatitude != null) 'customer_latitude': customerLatitude,
      if (customerLongitude != null) 'customer_longitude': customerLongitude,
    });
    return res as Map<String, dynamic>;
  }

  /// Lightweight pickup-only estimate (no ML). Calls POST /pickup/estimate
  Future<Map<String, dynamic>> getPickupEstimate({
    required int tailorId,
    required double latitude,
    required double longitude,
  }) async {
    final res = await api.post('/pickup/estimate', {
      'tailor_id': tailorId,
      'latitude': latitude,
      'longitude': longitude,
    });
    return res as Map<String, dynamic>;
  }

  Future<List<PickupSlotOption>> getAvailablePickupSlots({
    required int tailorId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final res = await api.get('/tailors/$tailorId/available-slots?date=$dateStr');
    final data = res['data'] as List;
    return data.map((e) => PickupSlotOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Langkah 11-12: Pelanggan setujui estimasi & kirim pesanan ke penjahit
  Future<Order> createOrder({
    required int tailorId,
    required int categoryId,
    String? description,
    String? photoPath,
    required DateTime deadline,
    required double estimatedPrice,
    DateTime? pickupTanggal,
    String? pickupJamMulai,
    String? pickupJamSelesai,
    double? customerLatitude,
    double? customerLongitude,
    String? customerAddress,
  }) async {
    final body = {
      'tailor_id': tailorId,
      'category_id': categoryId,
      'description': description,
      'photo_path': photoPath,
      'deadline': deadline.toIso8601String().split('T').first,
      'estimated_price': estimatedPrice,
      if (customerLatitude != null) 'customer_latitude': customerLatitude,
      if (customerLongitude != null) 'customer_longitude': customerLongitude,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (pickupTanggal != null) 'pickup_tanggal': pickupTanggal.toIso8601String().split('T').first,
      if (pickupJamMulai != null) 'pickup_jam_mulai': pickupJamMulai,
      if (pickupJamSelesai != null) 'pickup_jam_selesai': pickupJamSelesai,
    };

    final res = await api.post('/orders', body);
    return Order.fromJson(res);
  }

  /// Langkah 15-16: Pelanggan pilih metode pembayaran -> dapatkan snap token Midtrans
  Future<String> requestPayment({
    required int orderId,
    required String paymentType, // 'dp' atau 'pelunasan'
    required double amount,
  }) async {
    final res = await api.post('/orders/$orderId/pay', {
      'payment_type': paymentType,
      'amount': amount,
    });
    return res['snap_token'] as String;
  }

  Future<Order> cancelOrder(int orderId) async {
    final res = await api.post('/orders/$orderId/cancel', {});
    return Order.fromJson(res);
  }

  Future<Order> requestOrderCancellation(int orderId) async {
    final res = await api.post('/orders/$orderId/request-cancellation', {});
    return Order.fromJson(res);
  }

  /// Tracking status pesanan (F-06)
  Future<Order> getOrderDetail(int orderId) async {
    final res = await api.get('/orders/$orderId');
    return Order.fromJson(res);
  }

  /// Langkah 21-22: Beri ulasan & rating setelah pesanan selesai
  Future<void> submitReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    await api.post('/orders/$orderId/review', {
      'rating': rating,
      'comment': comment,
    });
  }
}
