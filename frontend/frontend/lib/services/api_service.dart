import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/review.dart';
import '../models/tailor.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
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
      if (category != null && category.isNotEmpty)
        queryParameters['category'] = category;
      if (minRating != null)
        queryParameters['min_rating'] = minRating.toString();
      final uri = Uri.parse('$baseUrl/tailors').replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      final response = await http.get(uri, headers: headers());
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == 'success') {
        final rawTailors = body['data']['tailors'];
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
            name: 'Rina',
            shopName: 'Rina Tailor',
            city: 'Jakarta',
            specializations: ['Permak', 'Alterasi'],
            rating: 4.8,
            isAvailable: true,
            reviewsCount: 125,
            distanceKm: 1.4,
            portfolio: [
              'https://via.placeholder.com/120',
              'https://via.placeholder.com/120',
            ],
            description: 'Penjahit terpercaya dengan hasil rapi dan cepat.',
          ),
          Tailor(
            id: 'demo-2',
            name: 'Aldi',
            shopName: 'Aldi Sewing',
            city: 'Bandung',
            specializations: ['Alterasi', 'Jahit Custom'],
            rating: 4.6,
            isAvailable: true,
            reviewsCount: 98,
            distanceKm: 2.3,
            portfolio: ['https://via.placeholder.com/120'],
            description: 'Spesialis jahit custom dan pemeliharaan pakaian.',
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

  static Future<Order> createOrder({
    required String tailorId,
    required String category,
    required String description,
    required String deadline,
    required String deliveryMode,
    List<String> photos = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers(),
      body: jsonEncode({
        'tailor_id': tailorId,
        'category': category,
        'description': description,
        'photos': photos,
        'deadline': deadline,
        'delivery_mode': deliveryMode,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && body['status'] == 'success') {
      return Order.fromJson(body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Gagal membuat pesanan');
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

  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: headers(),
    );
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
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;

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
