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

  /// Mengunggah file gambar dan mengembalikan `path` relatif (mis. `uploads/abc.jpg`)
  /// yang siap dikirim sebagai `photo_path` ke `OrderService.getPriceEstimate`/`createOrder`.
  Future<String> uploadImage(dynamic pickedFile) async {
    final uri = api.buildUri('/uploads');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(api.authHeaders);

    // Read bytes in a cross-platform way. `pickedFile` is expected to be
    // an XFile (from image_picker/file_picker) which exposes `readAsBytes()`
    // on all platforms including web. We avoid importing dart:io here so the
    // file compiles on Web.
    Uint8List bytes;
    String filename = 'upload.jpg';

    try {
      bytes = await pickedFile.readAsBytes();
      filename =
          (pickedFile.name ?? pickedFile.path?.split('/')?.last) ?? filename;
    } catch (e) {
      throw Exception('Cannot read bytes from selected file: $e');
    }

    final multipart =
        http.MultipartFile.fromBytes('file', bytes, filename: filename);
    request.files.add(multipart);

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
