import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL untuk backend Laravel TailorLX.
///
/// Untuk platform web, base URL diambil otomatis dari origin browser saat ini
/// (misalnya http://127.0.0.1:8000 atau https://abc123.ngrok-free.app).
/// Untuk platform mobile, tetap memakai konfigurasi dari `.env` atau fallback
/// lokal. Untuk Android emulator, `127.0.0.1` digantikan dengan `10.0.2.2`.
String get apiBaseUrl {
  if (kIsWeb) {
    return Uri.base.origin;
  }

  final rawUrl = dotenv.env['API_BASE_URL']?.trim();
  if (rawUrl != null && rawUrl.isNotEmpty) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return rawUrl
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
    }
    return rawUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }

  return 'http://127.0.0.1:8000';
}
