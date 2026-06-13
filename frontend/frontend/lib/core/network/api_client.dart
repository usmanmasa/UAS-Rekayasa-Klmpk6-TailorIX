import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._internal() {
    dio = _createDio(_apiV1BaseUrl, true);
    publicDio = _createDio(_apiBaseUrl, false);
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;
  late final Dio publicDio;

  static const String _apiV1BaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String _apiBaseUrl = 'http://127.0.0.1:8000/api';
  static const String _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Dio _createDio(String baseUrl, bool attachAuth) {
    final client = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (attachAuth) {
      client.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final responseCode = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final shouldRefresh = responseCode == 401 && requestOptions.extra['retried'] != true;

          if (shouldRefresh) {
            try {
              final refreshResponse = await client.post('/auth/refresh');
              final refreshBody = refreshResponse.data;
              if (refreshBody is Map<String, dynamic>) {
                final newToken = refreshBody['data']?['access_token'] as String?;
                if (newToken != null && newToken.isNotEmpty) {
                  await _storage.write(key: _accessTokenKey, value: newToken);
                  requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  requestOptions.extra['retried'] = true;
                  final retryResponse = await client.fetch(requestOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {
              await _storage.deleteAll();
            }
          }

          return handler.next(error);
        },
      ));
    }

    return client;
  }
}
