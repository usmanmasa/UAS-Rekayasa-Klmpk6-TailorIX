import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    await ApiService.initialize();
    return ApiService.currentUser;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final user = await ApiService.login(email: email, password: password);
    state = AsyncValue.data(user);
    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? address,
    String? shopName,
    bool termsAccepted = false,
  }) async {
    state = const AsyncValue.loading();
    final user = await ApiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      address: address,
      shopName: shopName,
      termsAccepted: termsAccepted,
    );
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> logout() async {
    await ApiService.logout();
    state = const AsyncValue.data(null);
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? shopName,
    List<String>? specializations,
    List<String>? portfolio,
    double? locationLat,
    double? locationLng,
  }) async {
    state = const AsyncValue.loading();
    final user = await ApiService.updateProfile(
      name: name,
      phone: phone,
      address: address,
      shopName: shopName,
      specializations: specializations,
      portfolio: portfolio,
      locationLat: locationLat,
      locationLng: locationLng,
    );
    state = AsyncValue.data(user);
    return user;
  }
}
