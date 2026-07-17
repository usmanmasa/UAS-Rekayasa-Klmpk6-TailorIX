#!/usr/bin/env bash
#
# setup_flutter_project.sh — Lengkapi package ini (lib/ + pubspec.yaml saja)
# jadi project Flutter yang bisa langsung di-Run dari VS Code.
#
# Kenapa perlu skrip ini? Folder platform native (android/, ios/, web/) berisi
# file yang dihasilkan (termasuk file biner seperti Gradle wrapper) yang harus
# dibuat oleh Flutter SDK versi kamu sendiri — bukan sesuatu yang aman ditulis
# manual di luar Flutter SDK asli, karena gampang mismatch versi.
#
# CARA PAKAI:
#   1. Install Flutter SDK dulu kalau belum: https://docs.flutter.dev/get-started/install
#   2. Buka folder `frontend/` ini di terminal (atau lewat VS Code > Terminal > New Terminal)
#   3. Jalankan: ./setup_flutter_project.sh
#   4. Buka folder ini di VS Code, pasang extension "Flutter" (Dart-Code.flutter)
#   5. Tekan F5, atau jalankan `flutter run` dari terminal
#
# Skrip ini AMAN dijalankan di folder yang sudah berisi lib/ & pubspec.yaml —
# `flutter create` pada folder yang sudah punya project akan menambahkan
# folder platform yang belum ada TANPA menimpa lib/ atau daftar dependency
# di pubspec.yaml (perilaku resmi Flutter untuk "add platform support to an
# existing package").

set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v flutter &>/dev/null; then
  echo "❌ 'flutter' tidak ditemukan di PATH."
  echo "   Install Flutter SDK dulu: https://docs.flutter.dev/get-started/install"
  echo "   Lalu jalankan ulang skrip ini."
  exit 1
fi

echo "== Menambahkan kerangka platform (android, ios, web) ke project ini... =="
flutter create --org com.tailorlx --project-name tailorlx_frontend \
  --platforms=android,ios,web .

echo ""
echo "== Mengambil dependency (flutter pub get)... =="
flutter pub get

echo ""
echo "== Selesai! =="
cat <<'EOF'

Langkah selanjutnya:
1. Buka folder ini di VS Code (kalau belum), pasang extension "Flutter"
   (Dart-Code.flutter) kalau belum ada — sudah direkomendasikan otomatis
   lewat .vscode/extensions.json.
2. Jalankan aplikasi: tekan F5, atau `flutter run` dari terminal
   (pastikan ada emulator/device aktif, atau pilih Chrome untuk web).
3. Fitur push notification (FCM) & Google Sign-In BELUM aktif sampai kamu:
   - Jalankan `flutterfire configure` untuk generate firebase_options.dart,
     lalu di lib/main.dart ganti baris `Firebase.initializeApp()` jadi
     `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
   - Daftarkan OAuth Client ID di Google Cloud Console untuk Google Sign-In.
   Tanpa 2 langkah itu, aplikasi tetap bisa dipakai normal (login
   email/password, pesan, chat, dll) — hanya push notification & Google
   Sign-In yang belum aktif.
4. Sambungkan ke backend: lihat lib/services/api_client.dart — defaultnya
   sudah http://10.0.2.2:8000/api (alamat khusus Android emulator untuk
   mengakses localhost mesin kamu). Ganti ke http://localhost:8000/api kalau
   run di Chrome/web, atau ke http://<IP-lokal-komputer>:8000/api kalau run
   di device fisik/iOS simulator yang beda jaringan dari `php artisan serve`.
EOF
