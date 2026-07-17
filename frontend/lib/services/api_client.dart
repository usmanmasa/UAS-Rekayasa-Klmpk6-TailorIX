import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

/// Wrapper HTTP untuk komunikasi ke backend Laravel TailorLX.
class ApiClient {
  // Singleton pattern: semua panggilan `ApiClient()` mengembalikan instance yang sama
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();
  /// Override host untuk perangkat lokal jika backend dijalankan di laptop/PC.
  ///
  /// Contoh: 'http://192.168.70.75:8000'
  static String? customHost;

  static String get baseUrl {
    if (customHost != null && customHost!.isNotEmpty) {
      final host = customHost!.replaceFirst(RegExp(r'/api/?\z'), '');
      return '$host/api';
    }

    return '$apiBaseUrl/api';
  }

  static String get baseHost {
    if (customHost != null && customHost!.isNotEmpty) {
      return customHost!.replaceFirst(RegExp(r'/api/?\z'), '');
    }

    return apiBaseUrl;
  }

  static String assetUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final normalized = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseHost/storage$normalized';
  }

  static String storageProxyUrl(String relativePath) {
    // If caller passed a full URL (e.g. backend returned "http://127.0.0.1:8000/storage/...")
    // rewrite it to use our proxy route so the browser gets CORS headers.
    try {
      if (relativePath.startsWith('http')) {
        final uri = Uri.parse(relativePath);
        final path = uri.path; // e.g. /storage/profile_photos/xxx.jpg
        if (path.startsWith('/storage/')) {
          // keep path after `/storage`
          final proxied = path.replaceFirst('/storage', '');
          return '$baseHost/storage-proxy$proxied';
        }
        // Not a storage asset, return as-is.
        return relativePath;
      }
    } catch (_) {
      // If parsing fails, fall back to treating value as relative path below.
    }

    final normalized = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseHost/storage-proxy$normalized';
  }

  /// Set true jika `MIDTRANS_IS_PRODUCTION=true` di backend (server key produksi).
  static const bool isMidtransProduction = false;
  /// Timeout sementara untuk debugging: 15 detik.
  /// Ini hanya dipakai sementara agar request lokal tidak langsung timeout saat
  /// kita menganalisis bottleneck server atau middleware.
  static const Duration requestTimeout = Duration(seconds: 15);

  String? _token; // Bearer token Sanctum, diisi setelah login

  static const _kAuthTokenKey = 'auth_token';

  /// Set token di memori dan simpan ke SharedPreferences.
  Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_kAuthTokenKey);
      } else {
        await prefs.setString(_kAuthTokenKey, token);
      }
    } catch (_) {
      // jika penyimpanan gagal, tetap lanjutkan — token tetap ada di memori
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAuthTokenKey);
    } catch (_) {}
  }

  /// Muat token dari SharedPreferences ke memori (dipanggil saat init app).
  Future<void> loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_kAuthTokenKey);
      _token = t != null && t.isNotEmpty ? t : null;
    } catch (_) {
      _token = null;
    }
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  bool _requiresAuth(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    const unauthenticatedPaths = [
      '/login',
      '/register',
      '/login/google',
      '/forgot-password',
      '/reset-password',
    ];
    return !unauthenticatedPaths.contains(normalized);
  }

  static Map<String, String> get _defaultJsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _headers => {
        ..._defaultJsonHeaders,
        if (hasToken) 'Authorization': 'Bearer $_token',
      };

  /// Global handler untuk token expired/unauthenticated (HTTP 401).
  /// Aplikasi dapat mengisi callback ini (mis. di main.dart) untuk
  /// menavigasi kembali ke halaman login.
  static void Function()? onUnauthenticated;

  /// Header otorisasi tanpa `Content-Type`, dipakai untuk request multipart
  /// (mis. upload file) yang Content-Type-nya diatur otomatis oleh `http`.
  Map<String, String> get authHeaders => {
        'Accept': 'application/json',
        if (hasToken) 'Authorization': 'Bearer $_token',
      };

  void _handleUnauthenticated() {
    clearToken();
    if (onUnauthenticated != null) {
      try {
        onUnauthenticated!();
      } catch (_) {}
    }
  }

  Uri buildUri(String path) {
    final prefix = path.startsWith('/') ? '' : '/';
    return Uri.parse('$baseUrl$prefix$path');
  }

  Future<dynamic> get(String path) async {
    if (_requiresAuth(path) && !hasToken) {
      _handleUnauthenticated();
      throw ApiException(401, 'Unauthenticated: token missing');
    }

    final uri = buildUri(path);
    try {
      final res = await http.get(uri, headers: _headers).timeout(requestTimeout);
      return _handle(res);
    } on SocketException catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Permintaan ke server timeout setelah ${requestTimeout.inSeconds} detik.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (_requiresAuth(path) && !hasToken) {
      _handleUnauthenticated();
      throw ApiException(401, 'Unauthenticated: token missing');
    }

    final uri = buildUri(path);
    try {
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      return _handle(res);
    } on SocketException catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Permintaan ke server timeout setelah ${requestTimeout.inSeconds} detik.');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = buildUri(path);
    try {
      final res = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      return _handle(res);
    } on SocketException catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Permintaan ke server timeout setelah ${requestTimeout.inSeconds} detik.');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = buildUri(path);
    try {
      final res = await http.delete(uri, headers: _headers).timeout(requestTimeout);
      return _handle(res);
    } on SocketException catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Permintaan ke server timeout setelah ${requestTimeout.inSeconds} detik.');
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = buildUri(path);
    try {
      final res = await http
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      return _handle(res);
    } on SocketException catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: ${e.message}');
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Permintaan ke server timeout setelah ${requestTimeout.inSeconds} detik.');
    }
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      // clear token from storage and memory
      clearToken();
      // call global handler if set
      if (onUnauthenticated != null) {
        try {
          onUnauthenticated!();
        } catch (_) {}
      }
    }
    throw ApiException(res.statusCode, res.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
