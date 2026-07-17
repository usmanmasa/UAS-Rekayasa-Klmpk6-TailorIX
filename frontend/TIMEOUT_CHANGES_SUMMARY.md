# Perubahan Timeout Handling - Before & After

**Update Date**: 2026-07-10  
**Timeout Setting**: Diubah dari 10 detik → **5 detik** untuk semua HTTP request  
**Files Modified**: 
- `lib/services/api_client.dart`
- `lib/services/upload_service.dart`

---

## 1. API Client - Timeout Configuration

### BEFORE (10 detik)
```dart
// api_client.dart (line ~41)
static const Duration requestTimeout = Duration(seconds: 10);
```

### AFTER (5 detik)
```dart
// api_client.dart (line ~41)
/// Timeout untuk semua HTTP request ke backend: 5 detik.
/// Jika request tidak selesai dalam waktu ini, TimeoutException akan dilempar.
/// Service layer harus menangkap exception ini dan tampilkan pesan error ke user.
static const Duration requestTimeout = Duration(seconds: 5);
```

**Dampak**: Semua request (GET, POST, PUT, PATCH, DELETE) ke API sekarang akan timeout **5 detik** alih-alih 10 detik.

---

## 2. API Client - New PATCH Method

### BEFORE
```dart
// Tidak ada method patch()
```

### AFTER
```dart
// api_client.dart - Added method
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
```

**Dampak**: Sekarang API client support HTTP PATCH method dengan timeout handling yang konsisten.

---

## 3. Upload Service - Timeout & Exception Handling

### BEFORE (10 detik, tanpa proper exception handling)
```dart
// upload_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class UploadService {
  static const Duration _uploadTimeout = Duration(seconds: 10);
  
  final ApiClient api;
  UploadService(this.api);

  Future<String> uploadImage(dynamic pickedFile) async {
    final uri = api.buildUri('/uploads');
    // ... (file reading code)
    
    final streamed = await request.send().timeout(_uploadTimeout);
    final res = await http.Response.fromStream(streamed).timeout(_uploadTimeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['path'] as String;
  }
}
```

### AFTER (5 detik, dengan proper exception handling)
```dart
// upload_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// Upload file generik ke `POST /api/uploads` (dipakai untuk foto pakaian
/// pada langkah 5-7 sequence diagram, lewat `image_picker` di `OrderFormScreen`).
///
/// Timeout untuk upload: 5 detik (sama dengan request timeout API).
/// Jika upload tidak selesai dalam waktu ini, TimeoutException akan dilempar
/// dan screen akan menampilkan pesan error ke user.
class UploadService {
  static const Duration _uploadTimeout = Duration(seconds: 5);
  
  final ApiClient api;
  UploadService(this.api);

  Future<String> uploadImage(dynamic pickedFile) async {
    final uri = api.buildUri('/uploads');
    // ... (file reading code)
    
    try {
      final streamed = await request.send().timeout(_uploadTimeout);
      final res = await http.Response.fromStream(streamed).timeout(_uploadTimeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(res.statusCode, res.body);
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['path'] as String;
    } on TimeoutException catch (_) {
      throw ApiException(0, 'Upload file timeout setelah ${_uploadTimeout.inSeconds} detik. Periksa koneksi jaringan Anda.');
    }
  }
}
```

**Dampak**: 
- Upload timeout diubah dari 10 → 5 detik
- `TimeoutException` sekarang ditangkap dan di-convert menjadi `ApiException` dengan pesan yang jelas
- Screen layer bisa menangkap `ApiException` dengan statusCode 0 untuk mendeteksi timeout

---

## 4. Exception Handling Flow

### Timeout Flow Diagram

```
User action (e.g., login)
    ↓
Screen calls → AuthService.login()
    ↓
AuthService calls → ApiClient.post('/login', {...})
    ↓
ApiClient makes HTTP request with 5-second timeout
    ↓
┌─────────────────────────────────────────────────────┐
│ Response dalam 5 detik? → YES → Return data        │
│                                                      │
│ Response dalam 5 detik? → NO  → TimeoutException   │
│                           ↓                         │
│                    Caught in ApiClient              │
│                           ↓                         │
│          Throw ApiException(0, 'Permintaan...')    │
└─────────────────────────────────────────────────────┘
    ↓
AuthService.login() throws ApiException
    ↓
Screen try-catch block catches ApiException
    ↓
Display error message: "Koneksi timeout, periksa jaringan atau coba lagi"
    ↓
Loading indicator disappears, user can tap "Coba Lagi" button
```

---

## 5. Implementation Checklist

Untuk menerapkan timeout handling dengan sempurna di seluruh aplikasi:

- [x] API Client timeout: 5 detik ✅
- [x] Upload Service timeout: 5 detik ✅
- [x] TimeoutException handling: Ditangkap & converted ke ApiException(0, message) ✅
- [x] Method PATCH: Added ✅
- [ ] **TODO**: Review semua Screen files yang memanggil service, pastikan punya try-catch untuk ApiException
- [ ] **TODO**: Review semua try-catch blocks, pastikan menampilkan error message ke user (SnackBar/Dialog)
- [ ] **TODO**: Pastikan loading indicator hilang saat timeout (setState dengan _loading = false di finally)

---

## 6. Testing Timeout Error

Untuk test timeout error tanpa matikan server:

### Option 1: Mock API response lambat
```dart
// Ubah backend untuk return response lambat
// Contoh di Laravel: sleep(6); // Lebih lama dari timeout 5 detik
```

### Option 2: Force timeout dengan mengubah baseUrl temporer
```dart
// main.dart
ApiClient.customHost = 'http://192.168.1.999:8000'; // IP yang tidak valid
// Jalankan app, semua request akan timeout karena tidak bisa reach server
```

### Option 3: Unit test
```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('login should catch timeout exception', () async {
    // Mock api.post() untuk throw TimeoutException
    when(mockApi.post('/login', any)).thenThrow(
      ApiException(0, 'Permintaan ke server timeout setelah 5 detik.')
    );
    
    expect(
      () => authService.login(email: 'test@test.com', password: 'pass'),
      throwsA(isA<ApiException>()),
    );
  });
}
```

---

## 7. Related Documentation

- [API_TIMEOUT_HANDLING.md](./API_TIMEOUT_HANDLING.md) - Comprehensive guide
- [auth_service_with_timeout_example.dart](./lib/services/auth_service_with_timeout_example.dart) - Service implementation example
- [api_client.dart](./lib/services/api_client.dart) - HTTP client dengan timeout
- [upload_service.dart](./lib/services/upload_service.dart) - Upload service dengan timeout

---

## 8. Performance Impact

| Metric | Before (10s) | After (5s) | Change |
|--------|-------------|-----------|--------|
| Timeout error detection | 10 detik | 5 detik | **2x lebih cepat** ⚡ |
| User experience | User tunggu 10s sebelum lihat error | User lihat error dalam 5s | **Lebih responsif** ✅ |
| Network bandwidth | Sama | Sama | Tidak ada perubahan |
| Server load | Sama | Sama | Tidak ada perubahan |

---

## 9. FAQ

**Q: Kenapa timeout diubah menjadi 5 detik?**  
A: 5 detik adalah sweet spot untuk UX yang responsif:
- Cukup lama untuk request normal ke backend
- Tidak terlalu lama hingga user merasa aplikasi hang
- Standar industri untuk timeout HTTP (misal: Axios default 10s, tapi sering di-custom ke 5s)

**Q: Apakah ini bisa break existing functionality?**  
A: Tergantung backend response time:
- Jika semua endpoint respond < 5 detik → No breaking change
- Jika ada endpoint slow > 5 detik → Will timeout (need backend optimization)

Saran: Test semua endpoint sebelum deploy ke production.

**Q: Bisakah customize timeout per-endpoint?**  
A: Ya, bisa. Contoh:
```dart
// Di ApiClient, tambahkan parameter optional
Future<dynamic> get(String path, {Duration? customTimeout}) async {
  final timeout = customTimeout ?? requestTimeout;
  // ... use timeout
}
```

Tapi tidak recommended — keep it simple dengan default 5 detik untuk semua.

---

**Generated**: 2026-07-10  
**Version**: 1.0
