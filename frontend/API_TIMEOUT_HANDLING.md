## API Timeout Handling - Best Practices

> **Versi**: 2026-07-10  
> **Timeout Duration**: 5 detik untuk semua HTTP request  
> **File Terkait**: 
> - `lib/services/api_client.dart` (HTTP client dengan timeout)
> - `lib/services/upload_service.dart` (Upload file dengan timeout)

---

## 1. Timeout Configuration

### API Request Timeout (5 detik)
Semua HTTP request (GET, POST, PUT, PATCH, DELETE) ke backend memiliki timeout **5 detik**.

```dart
// api_client.dart
static const Duration requestTimeout = Duration(seconds: 5);
```

Jika request tidak selesai dalam 5 detik, `TimeoutException` akan dilempar dan ditangkap sebagai `ApiException`:
```dart
throw ApiException(0, 'Permintaan ke server timeout setelah 5 detik.');
```

### Upload File Timeout (5 detik)
Upload file juga memiliki timeout **5 detik**:
```dart
// upload_service.dart
static const Duration _uploadTimeout = Duration(seconds: 5);
```

---

## 2. Exception Types

### TimeoutException
Dilempar ketika request/upload melebihi 5 detik tanpa response.

**Ditangkap sebagai:**
```dart
throw ApiException(0, 'Permintaan ke server timeout setelah 5 detik.');
throw ApiException(0, 'Upload file timeout setelah 5 detik. Periksa koneksi jaringan Anda.');
```

### ApiException
Custom exception dengan `statusCode` dan `body`:
```dart
class ApiException implements Exception {
  final int statusCode;  // 0 untuk timeout/network error, atau HTTP status code (401, 404, 500, dll)
  final String body;     // Pesan error dari server atau error message
  ApiException(this.statusCode, this.body);
}
```

---

## 3. Service Layer Error Handling

### Template: Menangkap Timeout Exception di Service

```dart
// services/my_service.dart
class MyService {
  final ApiClient api;
  MyService(this.api);

  Future<MyModel> fetchData() async {
    try {
      final res = await api.get('/my-endpoint');
      return MyModel.fromJson(res);
    } on ApiException catch (e) {
      // e.statusCode == 0 berarti timeout/network error
      if (e.statusCode == 0) {
        // Timeout atau network error
        rethrow; // Biarkan screen layer handle UI
      } else if (e.statusCode == 401) {
        // Unauthorized
        throw ApiException(401, 'Sesi Anda telah berakhir. Silakan login kembali.');
      } else {
        // Server error atau error lainnya
        rethrow;
      }
    }
  }
}
```

---

## 4. Screen Layer Error Handling

### Template: Menampilkan Error Message ke User

Contoh di screen yang memanggil API:

```dart
// screens/my_screen.dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.myService.fetchData();
      setState(() => _data = data);
    } on ApiException catch (e) {
      // Tangkap timeout dan error lainnya
      String errorMessage;
      
      if (e.statusCode == 0) {
        // Timeout atau network error
        errorMessage = e.body; // Sudah berisi pesan "Permintaan timeout setelah 5 detik."
      } else if (e.statusCode == 401) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
      } else if (e.statusCode == 404) {
        errorMessage = 'Data tidak ditemukan.';
      } else if (e.statusCode >= 500) {
        errorMessage = 'Server sedang bermasalah. Silakan coba lagi nanti.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.body}';
      }

      setState(() => _error = errorMessage);
      
      // Tampilkan SnackBar (opsional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : const Text('Data loaded successfully'),
    );
  }
}
```

---

## 5. Upload File Error Handling

### Template: Menangani Upload Timeout

```dart
// screens/my_upload_screen.dart
class MyUploadScreen extends StatefulWidget {
  @override
  State<MyUploadScreen> createState() => _MyUploadScreenState();
}

class _MyUploadScreenState extends State<MyUploadScreen> {
  bool _uploadingPhoto = false;

  Future<void> _uploadPhoto(dynamic pickedFile) async {
    setState(() => _uploadingPhoto = true);

    try {
      final photoPath = await widget.uploadService.uploadImage(pickedFile);
      // Upload berhasil
      setState(() => _photoPath = photoPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diunggah')),
      );
    } on ApiException catch (e) {
      String errorMessage;
      
      if (e.statusCode == 0) {
        // Timeout atau network error
        errorMessage = e.body; // "Upload file timeout setelah 5 detik..."
      } else {
        errorMessage = 'Gagal mengunggah foto: ${e.body}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Coba Lagi',
            onPressed: () => _uploadPhoto(pickedFile),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _uploadingPhoto
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengunggah foto...'),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: _pickAndUploadPhoto,
              child: const Text('Pilih & Unggah Foto'),
            ),
    );
  }
}
```

---

## 6. Checklist: Implementasi Timeout Handling

Sebelum menyelesaikan implementasi, pastikan semua poin berikut terpenuhi:

- [ ] **API Client** sudah set timeout 5 detik di semua method (get, post, put, patch, delete)
- [ ] **Upload Service** sudah set timeout 5 detik untuk upload file
- [ ] **TimeoutException** ditangkap sebagai `ApiException` dengan statusCode 0
- [ ] **Service Layer** menangkap `ApiException` dan re-throw atau handle sesuai kebutuhan
- [ ] **Screen Layer** memiliki try-catch yang menangkap `ApiException`
- [ ] **Loading indicator** (CircularProgressIndicator) otomatis hilang setelah timeout
- [ ] **Error message** ditampilkan ke user via SnackBar atau dialog
- [ ] **Retry button** disediakan untuk user coba lagi setelah timeout
- [ ] Semua HTTP endpoint di aplikasi sudah menggunakan pattern di atas (tidak ada yang ketinggalan)

---

## 7. Testing Timeout (Optional)

Untuk test timeout tanpa harus matikan server, Anda bisa:

1. **Ubah timeout endpoint di api_constants.dart** (temporer untuk testing):
   ```dart
   // Contoh, biasanya localhost:8000 sudah cepat
   // Untuk force timeout, ubah menjadi alamat yang tidak merespons cepat
   ```

2. **Atau mock API call di test**:
   ```dart
   // test/services/my_service_test.dart
   test('timeout error should show error message', () async {
     // Mock api.get() untuk throw TimeoutException
     when(mockApi.get('/endpoint')).thenThrow(
       ApiException(0, 'Permintaan ke server timeout setelah 5 detik.')
     );
     
     expect(
       () => myService.fetchData(),
       throwsA(isA<ApiException>()),
     );
   });
   ```

---

## 8. Q&A

**Q: Mengapa timeout 5 detik?**  
A: 5 detik adalah standar UX yang reasonable — cukup untuk request normal ke server lokal/cloud, tapi tidak cukup lama untuk user menunggu blank screen. Untuk upload file besar, Anda bisa extend timeout di upload method sendiri jika diperlukan.

**Q: Bagaimana jika user network lambat tapi stabil?**  
A: 5 detik sudah reasonable untuk network 3G/4G modern. Jika network user sangat lambat (2G), loading akan timeout. User harus switch ke WiFi atau network lebih cepat. Alternatively, Anda bisa add setting di app untuk custom timeout, tapi tidak recommended.

**Q: Apakah perlu retry logic otomatis?**  
A: Tidak perlu retry otomatis di API layer — biarkan user decide via retry button di UI. Automatic retry bisa cause double submission atau confusion.

**Q: Bagaimana kalau server response lambat tapi masih dalam 5 detik?**  
A: Tidak masalah, selama responsnya masuk dalam 5 detik, tidak akan timeout. Timeout hanya trigger jika ZERO response dalam 5 detik.

---

## Related Files
- [api_client.dart](../lib/services/api_client.dart) - HTTP client dengan timeout
- [upload_service.dart](../lib/services/upload_service.dart) - Upload service dengan timeout
- [Semua service files](../lib/services/) - Pastikan semua service layer menangkap ApiException
