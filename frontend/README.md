# TailorLX Frontend (Flutter)

Dokumentasi khusus frontend TailorLX yang dibangun dengan Flutter untuk aplikasi mobile dan web.

## Ringkasan

Frontend ini adalah antarmuka pengguna untuk TailorLX, melayani pelanggan dan mitra penjahit. Aplikasi mendukung tampilan adaptif untuk mobile dan web, integrasi peta, upload foto, chat, serta komunikasi dengan backend Laravel melalui REST API.

## Struktur Folder Utama

- `lib/` - kode sumber Flutter utama.
- `lib/screens/` - layar aplikasi untuk login, registrasi, pencarian, profil, pesan, chat, dan halaman penjahit.
- `lib/services/` - layanan API dan utilitas seperti `OrderService`, `AuthService`, `PushNotificationService`, dan pengaturan `ViewOverride`.
- `lib/widgets/` - widget ulang pakai, termasuk `SafeNetworkImage` untuk fallback gambar.
- `web/` - konfigurasi dan aset untuk Flutter Web.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/` - platform spesifik Flutter.
- `pubspec.yaml` - daftar dependency Flutter.

## Dependency Penting

Frontend TailorLX menggunakan paket berikut:

- `flutter` - SDK utama aplikasi.
- `google_fonts` - font kustom untuk tampilan.
- `shared_preferences` - menyimpan data lokal sederhana.
- `http` - komunikasi HTTP ke backend API.
- `firebase_messaging` - integrasi push notification FCM.
- `flutter_local_notifications` - menampilkan notifikasi lokal.
- `geolocator` - mengambil lokasi perangkat.
- `flutter_map` - menampilkan peta OpenStreetMap.
- `latlong2` - tipe koordinat untuk peta.
- `geocoding` - konversi alamat ke koordinat.
- `image_picker` - mengambil foto untuk upload portofolio dan profil.
- `url_launcher` - membuka URL eksternal seperti Midtrans Snap.
- `flutter_dotenv` - memuat variabel lingkungan dari `.env`.
- `pusher_client_socket` - koneksi realtime/chat jika diperlukan.

## Catatan Fitur Frontend

- Aplikasi mendukung **layout adaptif** untuk web dan desktop via wrapper `kIsWeb` dan breakpoint responsif.
- Ada helper `ViewOverride` yang memungkinkan memaksakan tampilan web dengan parameter URL `?view=web`.
- Gambar dari storage backend dibungkus dengan `SafeNetworkImage` untuk menangani error load gambar.
- Form chat, upload foto, dan status order terhubung dengan REST API backend.

## Menjalankan Frontend

### Install dependency

```bash
cd frontend
flutter pub get
```

### Jalankan versi mobile

```bash
flutter run
```

### Jalankan versi web

```bash
flutter run -d chrome
```

### Build untuk web

```bash
flutter build web
```

## Deploy Web ke Laravel

Setelah build web selesai, salin hasil build ke folder `backend/public` di project root:

```bash
cd frontend
flutter build web
robocopy "build\web" "..\backend\public" /E /XD storage /XF index.php .htaccess
```

Catatan:
- Pastikan `backend/public/index.php` dan `backend/public/.htaccess` tetap ada.
- Jangan hapus folder `backend/public/storage` saat menyalin build web.

## Catatan Pengembangan

- `frontend/pubspec.yaml` sudah menggunakan `flutter_map` sebagai pengganti `google_maps_flutter` agar dukungan web tetap tersedia.
- `Image.network` di beberapa halaman diganti atau dibungkus dengan `SafeNetworkImage` untuk fallback saat URL gambar tidak tersedia.
- `ViewOverride.initFromUri()` dipakai pada halaman pencarian dan homepage untuk mendukung parameter `?view=web`.
- Frontend berkomunikasi dengan backend Laravel menggunakan token Sanctum metode Bearer untuk endpoint API.

## Referensi Lain

- `../backend/README.md` untuk dokumentasi backend Laravel.
- `../README.md` untuk ringkasan dan overview project.
