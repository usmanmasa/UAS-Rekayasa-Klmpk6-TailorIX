import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/review.dart';
import '../models/tailor.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String publicBaseUrl = 'http://127.0.0.1:8000/api';
  static String? accessToken;
  static User? currentUser;

  static Map<String, String> headers() {
    final authHeader = accessToken != null
        ? {'Authorization': 'Bearer $accessToken'}
        : {};
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...authHeader,
    };
  }

  static bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return error is http.ClientException ||
        message.contains('failed host lookup') ||
        message.contains('clientfailed to fetch') ||
        message.contains('cors') ||
        message.contains('network');
  }

  static Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == 'success') {
        accessToken = body['data']['access_token'] as String?;
        final userJson = body['data']['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          currentUser = User.fromJson(userJson);
        } else {
          currentUser = User(
            id: '',
            name: email.split('@').first,
            email: email,
            phone: '',
            address: '',
            role: 'customer',
          );
        }
        return;
      }

      final message = body['message'] ?? 'Login gagal';
      throw Exception(message);
    } catch (error) {
      if (_isNetworkError(error)) {
        accessToken = 'demo-token';
        currentUser = User(
          id: 'demo',
          name: email.split('@').first,
          email: email,
          phone: '',
          address: '',
          role: 'customer',
        );
        return;
      }
      rethrow;
    }
  }

  static Future<void> register(
    String name,
    String email,
    String phone,
    String password, {
    String role = 'customer',
    String? address,
    String? shopName,
    bool termsAccepted = false,
  }) async {
    try {
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': role,
        'terms_accepted': termsAccepted,
      };
      if (address != null && address.isNotEmpty) {
        payload['address'] = address;
      }
      if (shopName != null && shopName.isNotEmpty) {
        payload['shop_name'] = shopName;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers(),
        body: jsonEncode(payload),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && body['status'] == 'success') {
        accessToken =
            body['data']['token'] as String? ??
            body['data']['access_token'] as String?;
        final userJson = body['data']['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          currentUser = User.fromJson(userJson);
        } else {
          currentUser = User(
            id: '',
            name: name,
            email: email,
            phone: phone,
            address: address ?? '',
            role: role,
          );
        }
        return;
      }

      final message = body['message'] ?? 'Registrasi gagal';
      throw Exception(message);
    } catch (error) {
      if (_isNetworkError(error)) {
        accessToken = 'demo-token';
        currentUser = User(
          id: 'demo',
          name: name,
          email: email,
          phone: phone,
          address: address ?? '',
          role: role,
        );
        return;
      }
      rethrow;
    }
  }

  static Future<List<Tailor>> fetchTailors({
    String query = '',
    String? category,
    double? minRating,
  }) async {
    try {
      final queryParameters = <String, String>{};
      if (query.isNotEmpty) queryParameters['q'] = query;
      if (category != null && category.isNotEmpty) queryParameters['category'] = category;
      if (minRating != null) queryParameters['min_rating'] = minRating.toString();
      final uri = Uri.parse('$publicBaseUrl/penjahit').replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      final response = await http.get(uri, headers: headers());
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == 'success') {
        final rawTailors = body['data']['penjahits'];
        final list = rawTailors is List
            ? rawTailors
            : (rawTailors['data'] as List<dynamic>? ?? []);
        return list
            .map((item) => Tailor.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception(body['message'] ?? 'Gagal memuat penjahit');
    } catch (error) {
      if (_isNetworkError(error)) {
        return [
          Tailor(
            id: 'demo-1',
            name: 'Sari',
            shopName: 'Bu Sari Taylor',
            city: 'Bandung, Jl. Sudirman',
            specializations: ['Permak', 'Alterasi', 'Jas'],
            rating: 4.8,
            isAvailable: true,
            reviewsCount: 145,
            distanceKm: 1.2,
            locationLat: -6.9175,
            locationLng: 107.6191,
            portfolio: [
              'https://via.placeholder.com/120',
              'https://via.placeholder.com/120',
            ],
            description: 'Penjahit profesional dengan hasil rapi dan cepat. Spesialis alterasi jas dan kasual wear.',
          ),
          Tailor(
            id: 'demo-2',
            name: 'Andi',
            shopName: 'Pak Andi Tailor',
            city: 'Bandung, Jl. Dago',
            specializations: ['Alterasi', 'Jahit Custom', 'Batik'],
            rating: 4.6,
            isAvailable: true,
            reviewsCount: 98,
            distanceKm: 2.3,
            locationLat: -6.8951,
            locationLng: 107.6099,
            portfolio: [
              'https://via.placeholder.com/120',
            ],
            description: 'Spesialis jahit custom dan pemeliharaan pakaian premium.',
          ),
          Tailor(
            id: 'demo-3',
            name: 'Rina',
            shopName: 'Jahit Cepat Mba Rina',
            city: 'Bandung, Jl. Cihampelas',
            specializations: ['Permak', 'Kasual', 'Seragam'],
            rating: 4.9,
            isAvailable: true,
            reviewsCount: 167,
            distanceKm: 2.8,
            locationLat: -6.8983,
            locationLng: 107.6066,
            portfolio: [
              'https://via.placeholder.com/120',
              'https://via.placeholder.com/120',
            ],
            description: 'Ahli dalam permak cepat dengan kualitas terbaik. Pengalaman 10+ tahun.',
          ),
          Tailor(
            id: 'demo-4',
            name: 'Ujang',
            shopName: 'Tailor Mang Ujang',
            city: 'Bandung, Jl. Braga',
            specializations: ['Jas', 'Formal', 'Wedding Dress'],
            rating: 4.7,
            isAvailable: true,
            reviewsCount: 203,
            distanceKm: 3.1,
            locationLat: -6.9214,
            locationLng: 107.6079,
            portfolio: [],
            description: 'Spesialis gaun pengantin dan pakaian formal berkualitas tinggi.',
          ),
          Tailor(
            id: 'demo-5',
            name: 'Dewi',
            shopName: 'Bu Dewi Fashion',
            city: 'Bandung, Jl. Buah Batu',
            specializations: ['Kebaya', 'Batik', 'Tradisional'],
            rating: 4.5,
            isAvailable: false,
            reviewsCount: 87,
            distanceKm: 4.2,
            locationLat: -6.9401,
            locationLng: 107.6318,
            portfolio: [
              'https://via.placeholder.com/120',
            ],
            description: 'Ahli dalam pakaian tradisional dan kebaya dengan desain modern.',
          ),
          Tailor(
            id: 'demo-6',
            name: 'Hendra',
            shopName: 'Tailor Pak Hendra',
            city: 'Bandung, Jl. Setiabudhi',
            specializations: ['Alterasi', 'Rok', 'Pakaian Wanita'],
            rating: 4.4,
            isAvailable: true,
            reviewsCount: 112,
            distanceKm: 3.5,
            locationLat: -6.8711,
            locationLng: 107.5997,
            portfolio: [
              'https://via.placeholder.com/120',
            ],
            description: 'Spesialis alterasi rok dan pakaian wanita dengan detail sempurna.',
          ),
        ];
      }
      rethrow;
    }
  }

  static Future<Tailor> fetchTailorDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tailors/$id'),
      headers: headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Tailor.fromJson(body['data']['tailor'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memuat detail penjahit');
  }

  static Future<Map<String, dynamic>> fetchAdminSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/summary'),
      headers: headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final response = await http.post(
      Uri.parse('$baseUrl/ml/estimate'),
      headers: headers(),
      body: jsonEncode({
        'category': category,
        'description': description,
        'photos': photos,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final queryParameters = <String, String>{};
    if (query.isNotEmpty) queryParameters['q'] = query;
    if (role != null && role.isNotEmpty) queryParameters['role'] = role;
    final uri = Uri.parse('$baseUrl/admin/users').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    final response = await http.get(uri, headers: headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawUsers = body['data']['users'];
      final list = rawUsers is List
          ? rawUsers
          : (rawUsers['data'] as List<dynamic>? ?? []);
      return list.map((item) => item as Map<String, dynamic>).toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat pengguna');
  }

  static Future<void> updateAdminUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: headers(),
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Gagal memperbarui pengguna');
    }
  }

  static Future<void> disableAdminUser({
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Gagal menonaktifkan pengguna');
    }
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
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers(),
      body: jsonEncode(body),
    );
    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && responseBody['status'] == 'success') {
      return Order.fromJson(responseBody['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(responseBody['message'] ?? 'Gagal membuat pesanan');
  }

  static Future<Order> acceptOrder({
    required String orderId,
    required double finalPrice,
    String? notes,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/accept'),
      headers: headers(),
      body: jsonEncode({'final_price': finalPrice, 'notes': notes}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal menerima pesanan');
  }

  static Future<Order> rejectOrder({
    required String orderId,
    String? notes,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/reject'),
      headers: headers(),
      body: jsonEncode({'notes': notes}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: headers(),
      body: jsonEncode({'status': status, 'notes': notes}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui status pesanan');
  }

  static Future<List<Order>> fetchOrders({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    final uri = Uri.parse('$baseUrl/orders').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final response = await http.get(uri, headers: headers());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final rawOrders = body['data']['orders'];
      final list = rawOrders is List
          ? rawOrders
          : (rawOrders['data'] as List<dynamic>? ?? []);
      return list
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Gagal memuat riwayat pesanan');
  }

  static Future<Order> fetchOrderDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: headers(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal memuat detail pesanan');
  }

  static Future<void> registerDeviceToken({
    required String deviceToken,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/profile/device-token'),
      headers: headers(),
      body: jsonEncode({'device_token': deviceToken}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return;
    }
    throw Exception(body['message'] ?? 'Gagal menyimpan device token');
  }

  static Future<void> updateDeviceToken(String token) async {
    return registerDeviceToken(deviceToken: token);
  }

  static Future<Review> submitReview({
    required String orderId,
    required double rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: headers(),
      body: jsonEncode({
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['status'] == 'success') {
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
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: headers(),
      body: jsonEncode({
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_type': paymentType,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Gagal memproses pembayaran');
    }
    return body['data']['payment'] as Map<String, dynamic>;
  }

  static Future<void> simulatePaymentSuccess({
    required String orderId,
    required String transactionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/webhook'),
      headers: headers(),
      body: jsonEncode({
        'order_id': orderId,
        'transaction_id': transactionId,
        'status': 'settlement',
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Gagal mensimulasikan pembayaran');
    }
  }

  static Future<void> updateProfile({
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

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: headers(),
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      final userJson = body['data']['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        currentUser = User.fromJson(userJson);
      }
      return;
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui profil');
  }

  static void logout() {
    accessToken = null;
    currentUser = null;
  }
}
