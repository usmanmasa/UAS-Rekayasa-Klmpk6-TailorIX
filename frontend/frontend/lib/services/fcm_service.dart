import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class FcmService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getToken();
  }

  static void listenOnTokenRefresh() {
    if (kIsWeb) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        try {
          await ApiService.updateDeviceToken(newToken);
        } catch (_) {
          // ignore errors, token will be updated later if possible
        }
      }
    });
  }

  static void listenOnForegroundMessage(
    Function(RemoteMessage) onMessage,
  ) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  static void listenOnMessageOpenedApp(
    Function(RemoteMessage) onTap,
  ) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getInitialMessage();
  }

  static Future<void> saveTokenToBackend() async {
    if (kIsWeb) return;
    final token = await getToken();
    if (token != null) {
      try {
        await ApiService.updateDeviceToken(token);
      } catch (_) {
        // accessToken mungkin belum tersedia saat app mulai
      }
    }
  }
}
