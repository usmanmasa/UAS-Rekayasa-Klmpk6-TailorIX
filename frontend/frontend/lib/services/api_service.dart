import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/tailor.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String publicBaseUrl = 'http://127.0.0.1:8000/api';
  static const String _accessTokenKey = 'access_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static User? currentUser;

  static Dio get _dio => ApiClient.instance.dio;
  static Dio get _publicDio => ApiClient.instance.publicDio;

  static Future<void> initialize() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        currentUser = await fetchProfile();
      } catch (_) {
        await logout();
      }
    }
  }

  static Future<void> _saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final accessToken = body['data']['access_token'] as String?;
      final userJson = body['data']['user'] as Map<String, dynamic>?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Login gagal: token tidak ditemukan');
      }

      await _saveToken(accessToken);
      currentUser = userJson != null
          ? User.fromJson(userJson)
          : User(
              id: '',
              name: email.split('@').first,
              email: email,
              phone: '',
              address: '',
              role: 'customer',
            );
      return currentUser!;
    }

    throw Exception(body['message'] ?? 'Login gagal');
  }

  static Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'customer',
    String? address,
    String? shopName,
    bool termsAccepted = false,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
      'role': role,
      'address': address,
      'shop_name': shopName,
      'terms_accepted': termsAccepted,
    });

    final body = response.data as Map<String, dynamic>;
    if ((response.statusCode == 201 || response.statusCode == 200) && body['status'] == 'success') {
      final accessToken = body['data']['token'] as String? ?? body['data']['access_token'] as String?;
      final userJson = body['data']['user'] as Map<String, dynamic>?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Registrasi gagal: token tidak ditemukan');
      }
      await _saveToken(accessToken);
      currentUser = userJson != null
          ? User.fromJson(userJson)
          : User(
              id: '',
              name: name,
              email: email,
              phone: phone,
              address: address ?? '',
              role: role,
            );
      return currentUser!;
    }

    throw Exception(body['message'] ?? 'Registrasi gagal');
  }

  static Future<List<Tailor>> fetchTailors({
    String query = '',
    String? category,
    double? minRating,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (query.isNotEmpty) queryParameters['q'] = query;
    if (category != null && category.isNotEmpty) queryParameters['category'] = category;
    if (minRating != null) queryParameters['min_rating'] = minRating.toString();

    final response = await _publicDio.get('/penjahit', queryParameters: queryParameters);
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawTailors = body['data']['penjahits'];
      final list = rawTailors is List ? rawTailors : (rawTailors['data'] as List<dynamic>? ?? []);
      return list.map((item) => Tailor.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat penjahit');
  }

  static Future<Tailor> fetchTailorDetail(String id) async {
    final response = await _dio.get('/tailors/$id');
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Tailor.fromJson(body['data']['tailor'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memuat detail penjahit');
  }

  static Future<Map<String, dynamic>> fetchAdminSummary() async {
    final response = await _dio.get('/admin/summary');
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Gagal memuat ringkasan admin');
  }

  static double _parseNumeric(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    }
    return 0.0;
  }

  static Future<Map<String, dynamic>> estimatePrice({
    required String category,
    required String description,
    required List<String> photos,
  }) async {
    final response = await _dio.post('/ml/estimate', data: {
      'category': category,
      'description': description,
      'photos': photos,
    });

    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final data = body['data'] as Map<String, dynamic>;
      return {
        'id': data['id'],
        'min_price': _parseNumeric(data['min_price']),
        'max_price': _parseNumeric(data['max_price']),
        'confidence': _parseNumeric(data['confidence']),
        'analysis': data['analysis'],
      };
    }
    throw Exception(body['message'] ?? 'Gagal menghitung estimasi harga');
  }

  static Future<List<Map<String, dynamic>>> fetchAdminUsers({
    String query = '',
    String? role,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (query.isNotEmpty) queryParameters['q'] = query;
    if (role != null && role.isNotEmpty) queryParameters['role'] = role;
    final response = await _dio.get('/admin/users', queryParameters: queryParameters);
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawUsers = body['data']['users'];
      final list = rawUsers is List ? rawUsers : (rawUsers['data'] as List<dynamic>? ?? []);
      return list.map((item) => item as Map<String, dynamic>).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat pengguna');
  }

  static Future<void> updateAdminUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.put('/admin/users/$userId', data: data);
    _validateResponse(response, 'Gagal memperbarui pengguna');
  }

  static Future<void> disableAdminUser({
    required String userId,
  }) async {
    final response = await _dio.delete('/admin/users/$userId');
    _validateResponse(response, 'Gagal menonaktifkan pengguna');
  }

  static Future<Order> createOrder({
    required String tailorId,
    required String category,
    required String description,
    required String deadline,
    required String deliveryMode,
    List<String> photos = const [],
    String? mlEstimationId,
  }) async {
    final body = {
      'tailor_id': tailorId,
      'category': category,
      'description': description,
      'photos': photos,
      'deadline': deadline,
      'delivery_mode': deliveryMode,
    };
    if (mlEstimationId != null && mlEstimationId.isNotEmpty) {
      body['ml_estimation_id'] = mlEstimationId;
    }
    final response = await _dio.post('/orders', data: body);
    final responseBody = response.data as Map<String, dynamic>;
    if ((response.statusCode == 201 || response.statusCode == 200) && responseBody['status'] == 'success') {
      return Order.fromJson(responseBody['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(responseBody['message'] ?? 'Gagal membuat pesanan');
  }

  static Future<Order> acceptOrder({
    required String orderId,
    required double finalPrice,
    String? notes,
  }) async {
    final response = await _dio.patch('/orders/$orderId/accept', data: {
      'final_price': finalPrice,
      'notes': notes,
    });
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal menerima pesanan');
  }

  static Future<Order> rejectOrder({
    required String orderId,
    String? notes,
  }) async {
    final response = await _dio.patch('/orders/$orderId/reject', data: {'notes': notes});
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal menolak pesanan');
  }

  static Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    final response = await _dio.patch('/orders/$orderId/status', data: {
      'status': status,
      'notes': notes,
    });
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui status pesanan');
  }

  static Future<List<Order>> fetchOrders({String? status}) async {
    final queryParameters = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    final response = await _dio.get('/orders', queryParameters: queryParameters);
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawOrders = body['data']['orders'];
      final list = rawOrders is List ? rawOrders : (rawOrders['data'] as List<dynamic>? ?? []);
      return list.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat riwayat pesanan');
  }

  static Future<Order> fetchOrderDetail(String id) async {
    final response = await _dio.get('/orders/$id');
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memuat detail pesanan');
  }

  static Future<User> fetchProfile() async {
    final response = await _dio.get('/profile');
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final userJson = body['data']['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw Exception('Profil pengguna tidak ditemukan');
      }
      currentUser = User.fromJson(userJson);
      return currentUser!;
    }
    throw Exception(body['message'] ?? 'Gagal memuat profil');
  }

  static Future<List<Tailor>> fetchFavorites() async {
    final response = await _dio.get('/customers/favorites');
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawFavorites = body['data']['favorites'];
      final list = rawFavorites is List ? rawFavorites : (rawFavorites['data'] as List<dynamic>? ?? []);
      return list.map((item) => Tailor.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat favorit');
  }

  static Future<void> addFavorite(String tailorId) async {
    final response = await _dio.post('/customers/favorites', data: {'tailor_id': tailorId});
    _validateResponse(response, 'Gagal menambahkan favorit');
  }

  static Future<void> removeFavorite(String favoriteId) async {
    final response = await _dio.delete('/customers/favorites/$favoriteId');
    _validateResponse(response, 'Gagal menghapus favorit');
  }

  static Future<void> registerDeviceToken({
    required String deviceToken,
  }) async {
    final response = await _dio.patch('/profile/device-token', data: {'device_token': deviceToken});
    _validateResponse(response, 'Gagal menyimpan device token');
  }

  static Future<void> updateDeviceToken(String token) async {
    return registerDeviceToken(deviceToken: token);
  }

  static Future<Review> submitReview({
    required String orderId,
    required double rating,
    required String comment,
  }) async {
    final response = await _dio.post('/reviews', data: {
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
    final body = response.data as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) && body['status'] == 'success') {
      final reviewJson = body['data']['review'] as Map<String, dynamic>?;
      if (reviewJson != null) {
        return Review.fromJson(reviewJson);
      }
      return Review(
        id: '',
        orderId: orderId,
        authorName: currentUser?.name ?? 'Pelanggan',
        rating: rating,
        comment: comment,
        photos: [],
      );
    }
    throw Exception(body['message'] ?? 'Gagal mengirim ulasan');
  }

  static Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required int amount,
    required String paymentMethod,
    required String paymentType,
  }) async {
    final response = await _dio.post('/payments', data: {
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
    });
    final body = response.data as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) && body['status'] == 'success') {
      return body['data']['payment'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Gagal memproses pembayaran');
  }

  static Future<void> simulatePaymentSuccess({
    required String orderId,
    required String transactionId,
  }) async {
    final response = await _dio.post('/payments/webhook', data: {
      'order_id': orderId,
      'transaction_id': transactionId,
      'status': 'settlement',
    });
    _validateResponse(response, 'Gagal mensimulasikan pembayaran');
  }

  static Future<User> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? shopName,
    List<String>? specializations,
    List<String>? portfolio,
    double? locationLat,
    double? locationLng,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (shopName != null) payload['shop_name'] = shopName;
    if (specializations != null) payload['specializations'] = specializations;
    if (portfolio != null) payload['portfolio'] = portfolio;
    if (locationLat != null) payload['location_lat'] = locationLat;
    if (locationLng != null) payload['location_lng'] = locationLng;

    final response = await _dio.put('/profile', data: payload);
    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final userJson = body['data']['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        currentUser = User.fromJson(userJson);
      }
      return currentUser ?? User(
        id: '',
        name: name ?? '',
        email: '',
        phone: phone ?? '',
        address: address ?? '',
        role: currentUser?.role ?? 'customer',
      );
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui profil');
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // ignore errors when logging out offline or with expired token
    }
    currentUser = null;
    await _storage.delete(key: _accessTokenKey);
  }

  static void _validateResponse(Response response, String message) {
    if (response.statusCode == null || response.statusCode! >= 400) {
      final body = response.data;
      final error = body is Map<String, dynamic> ? body['message'] : null;
      throw Exception(error ?? message);
    }
  }
}
