import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Modul F-01: Authentikasi & Manajemen Akun
/// 
/// IMPORTANT: Semua method di service ini menangkap ApiException (termasuk timeout)
/// dan re-throw dengan pesan yang jelas. Screen layer harus menangkap exception
/// ini dan tampilkan error message ke user.
/// 
/// Contoh:
/// ```dart
/// try {
///   final user = await authService.login(email: email, password: password);
/// } on ApiException catch (e) {
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(e.body), backgroundColor: Colors.red),
///   );
/// }
/// ```
class AuthServiceWithTimeoutHandling {
  final ApiClient api;
  AuthServiceWithTimeoutHandling(this.api);

  /// Register user baru.
  /// 
  /// Throw ApiException jika:
  /// - statusCode == 0: Timeout atau network error (pesan: "Permintaan timeout setelah 5 detik.")
  /// - statusCode >= 400: Server validation error atau server error
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
  }) async {
    try {
      final res = await api.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'phone': phone,
      });
      await api.setToken(res['token']);
      return AppUser.fromJson(res['user']);
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout atau network error
        rethrow; // Screen layer akan handle
      } else if (e.statusCode == 422) {
        // Validation error dari server
        rethrow;
      } else {
        rethrow;
      }
    }
  }

  /// Login dengan email dan password.
  /// 
  /// Throw ApiException jika:
  /// - statusCode == 0: Timeout (pesan akan berisi "Permintaan timeout setelah 5 detik.")
  /// - statusCode == 401: Email atau password salah
  /// - statusCode == 422: Validation error
  Future<AppUser> login({required String email, required String password}) async {
    try {
      final res = await api.post('/login', {'email': email, 'password': password});
      await api.setToken(res['token']);
      return AppUser.fromJson(res['user']);
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout — biarkan screen tampilkan pesan timeout default
        rethrow;
      } else if (e.statusCode == 401) {
        // Email atau password salah
        throw ApiException(401, 'Email atau password salah.');
      } else {
        rethrow;
      }
    }
  }

  /// Login dengan Google.
  /// 
  /// Throw ApiException jika timeout atau server error.
  Future<AppUser> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? photo,
  }) async {
    try {
      final res = await api.post('/login/google', {
        'google_id': googleId,
        'email': email,
        'name': name,
        'photo': photo,
      });
      await api.setToken(res['token']);
      return AppUser.fromJson(res['user']);
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout — rethrow agar screen bisa handle
        rethrow;
      } else {
        rethrow;
      }
    }
  }

  /// Request reset password via email.
  /// 
  /// Throw ApiException jika timeout atau server error.
  Future<void> forgotPassword(String email) async {
    try {
      await api.post('/forgot-password', {'email': email});
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout
        rethrow;
      } else if (e.statusCode == 404) {
        throw ApiException(404, 'Email tidak ditemukan di sistem.');
      } else {
        rethrow;
      }
    }
  }

  /// Reset password dengan token dari email.
  /// 
  /// Throw ApiException jika timeout, token invalid, atau server error.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await api.post('/reset-password', {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout
        rethrow;
      } else if (e.statusCode == 400 || e.statusCode == 422) {
        throw ApiException(400, 'Token reset password tidak valid atau sudah expired.');
      } else {
        rethrow;
      }
    }
  }

  /// Logout user (clear token dan notify server).
  /// 
  /// Throw ApiException jika timeout (tapi token akan tetap dihapus locally).
  Future<void> logout() async {
    try {
      await api.post('/logout', {});
    } on ApiException catch (e) {
      if (kDebugMode) print('Logout API error: $e');
      // Tetap clear token despite API error
    } finally {
      await api.clearToken();
    }
  }

  /// Fetch profile user yang sedang login.
  /// 
  /// Throw ApiException jika timeout atau unauthorized (401).
  Future<AppUser> getProfile() async {
    try {
      final res = await api.get('/profile');
      return AppUser.fromJson(res);
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout
        rethrow;
      } else if (e.statusCode == 401) {
        // Token sudah expired atau invalid
        await api.clearToken();
        throw ApiException(401, 'Sesi Anda telah berakhir. Silakan login kembali.');
      } else {
        rethrow;
      }
    }
  }

  /// Update profile user.
  /// 
  /// Throw ApiException jika timeout, validation error, atau unauthorized.
  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await api.put('/profile', data);
      return AppUser.fromJson(res);
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout
        rethrow;
      } else if (e.statusCode == 401) {
        await api.clearToken();
        throw ApiException(401, 'Sesi Anda telah berakhir. Silakan login kembali.');
      } else if (e.statusCode == 422) {
        // Validation error
        rethrow;
      } else {
        rethrow;
      }
    }
  }

  /// Delete account user.
  /// 
  /// Throw ApiException jika timeout, unauthorized, atau server error.
  Future<void> deleteAccount() async {
    try {
      await api.delete('/profile');
      await api.clearToken();
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Timeout
        rethrow;
      } else if (e.statusCode == 401) {
        await api.clearToken();
        throw ApiException(401, 'Sesi Anda telah berakhir.');
      } else {
        rethrow;
      }
    }
  }
}
