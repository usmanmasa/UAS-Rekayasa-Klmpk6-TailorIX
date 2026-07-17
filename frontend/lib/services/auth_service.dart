import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'api_client.dart';

/// Modul F-01: Authentikasi & Manajemen Akun
class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? phone,
  }) async {
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
  }

  Future<AppUser> login({required String email, required String password}) async {
    final res = await api.post('/login', {'email': email, 'password': password});
    await api.setToken(res['token']);
    return AppUser.fromJson(res['user']);
  }

  Future<AppUser> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? photo,
  }) async {
    final res = await api.post('/login/google', {
      'google_id': googleId,
      'email': email,
      'name': name,
      'photo': photo,
    });
    await api.setToken(res['token']);
    return AppUser.fromJson(res['user']);
  }

  Future<void> forgotPassword(String email) async {
    await api.post('/forgot-password', {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await api.post('/reset-password', {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout() async {
    try {
      await api.post('/logout', {});
    } finally {
      await api.clearToken();
    }
  }

  Future<AppUser> getProfile() async {
    final res = await api.get('/profile');
    return AppUser.fromJson(res);
  }

  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    final res = await api.put('/profile', data);
    return AppUser.fromJson(res);
  }

  /// Upload profile photo directly to server and return updated user.
  Future<AppUser> uploadProfilePhoto(dynamic pickedFile) async {
    final uri = api.buildUri('/profile/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(api.authHeaders);

    Uint8List bytes;
    String filename = 'profile.jpg';
    try {
      bytes = await pickedFile.readAsBytes();
      filename = (pickedFile.name ?? pickedFile.path?.split('/')?.last) ?? filename;
    } catch (e) {
      throw Exception('Cannot read selected file: $e');
    }

    final multipart = http.MultipartFile.fromBytes('photo', bytes, filename: filename);
    request.files.add(multipart);

    try {
      final streamed = await request.send().timeout(ApiClient.requestTimeout);
      final res = await http.Response.fromStream(streamed).timeout(ApiClient.requestTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(res.statusCode, res.body);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return AppUser.fromJson(data['user']);
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Upload timeout');
    }
  }

  Future<void> deleteAccount() async {
    await api.delete('/profile');
  }
}
