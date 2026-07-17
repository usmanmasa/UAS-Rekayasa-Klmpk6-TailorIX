# Software Requirements Specification for TailoriX
**Platform Digital Jasa Permak & Alterasi Pakaian**

**Version 1.0 Approved**  
Prepared by Tim Pengembang TailoriX  
Mata Kuliah: Rekayasa Perangkat Lunak  
April 2025

---
| Nama |
|------|
|melvy anjani |
|khansa mufidah |
|riphan romadlon|
|usman t masa|
|m. abdul azis|

**PROGRAM STUDI SISTEM INFORMASI**
**FAKULTAS ILMU KOMPUTER DAN SISTEM INFORMASI**
**UNIVERSITAS KEBANGSAAN REPUBLIK INDONESIA**
**TAHUN 2026**
## Revision History

| Name | Date | Reason For Changes | Version |
|------|------|-------------------|---------|
| Tim TailoriX | April 2025 | Initial release – dokumen SRS TailoriX v1.0 | 1.0 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [External Interface Requirements](#3-external-interface-requirements)
4. [System Features](#4-system-features)
5. [Other Nonfunctional Requirements](#5-other-nonfunctional-requirements)
6. [Other Requirements](#6-other-requirements)
7. [API Contract](#7-api-contract-desain-kontrak-api)
8. [Appendices](#appendices)

---

## 1. Introduction

### 1.1 Purpose

Dokumen Software Requirements Specification (SRS) ini mendeskripsikan spesifikasi kebutuhan perangkat lunak untuk aplikasi **TailoriX** – Platform Digital Jasa Permak & Alterasi Pakaian. Dokumen ini mencakup deskripsi fungsionalitas, antarmuka pengguna, kebutuhan non-fungsional, dan spesifikasi teknis sistem.

SRS ini disusun sebagai bagian dari mata kuliah Rekayasa Perangkat Lunak. Platform ini dibangun untuk menghubungkan pelanggan dengan penjahit mitra UMKM secara digital, transparan, dan terukur.

### 1.2 Document Conventions

Dokumen ini mengikuti konvensi penulisan sebagai berikut:

- **Heading 1 (H1)**: Judul bab utama, dicetak tebal, ukuran 14pt, warna biru tua.
- **Heading 2 (H2)**: Sub-bab, dicetak tebal, ukuran 12pt, warna biru.
- **Heading 3 (H3)**: Sub-sub-bab, dicetak tebal, ukuran 11pt, hitam.
- **ID Fitur**: Ditulis dengan format `F-XX` (contoh: F-01, F-02).
- **ID Requirement**: Ditulis dengan format `REQ-XX-YY` (contoh: REQ-01-01).
- **Kode API Endpoint**: Ditulis dengan format monospace (contoh: `/api/v1/auth/login`).
- **Prioritas fitur**: High (H), Medium (M), Low (L).

### 1.3 Intended Audience and Reading Suggestions

Dokumen SRS ini ditujukan untuk beberapa kelompok pembaca:

- **Developer & Software Engineer**: Fokus pada Bab 2 (Deskripsi Umum), Bab 3 (Kebutuhan Fungsional), Bab 4 (Antarmuka Eksternal), Bab 5 (Fitur Sistem), dan Bab 7 (Kontrak API).
- **Project Manager & Tim Akademik**: Fokus pada Bab 1 (Pendahuluan), Bab 2 (Deskripsi Umum), dan Bab 6 (Kebutuhan Nonfungsional).
- **System Analyst & Architect**: Fokus pada Bab 4 (Antarmuka), Bab 5 (Fitur Sistem), dan lampiran UML.
- **Tester & QA**: Fokus pada kebutuhan fungsional di Bab 5 dan atribut kualitas di Bab 6.

Disarankan untuk membaca dokumen secara berurutan dari Bab 1 hingga Bab 7, kemudian menelaah lampiran sesuai kebutuhan masing-masing peran.

### 1.4 Product Scope

TailoriX adalah platform digital berbasis mobile yang menghubungkan pelanggan dengan penjahit mitra UMKM penyedia jasa permak, alterasi, dan perbaikan pakaian. Platform ini dirancang untuk menjawab permasalahan kesulitan menemukan jasa permak berkualitas dan terpercaya di era digital.

**Manfaat utama platform ini meliputi:**

- Kemudahan akses layanan permak baju melalui smartphone (Android & iOS).
- Transparansi harga dengan estimasi otomatis berbasis Machine Learning.
- Tracking status pesanan secara real-time.
- Perluasan jangkauan usaha bagi penjahit mitra UMKM.
- Efisiensi proses bisnis melalui otomasi notifikasi (n8n).

**Platform TailoriX TIDAK mencakup:**
- Pembuatan pakaian baru dari awal
- Integrasi logistik pihak ketiga (v1.0)
- Fitur COD
- Versi web untuk pelanggan (v1.0)
- Dukungan multi-bahasa (v1.0 hanya Bahasa Indonesia)

### 1.5 References

- IEEE Std 830-1998, IEEE Recommended Practice for Software Requirements Specifications.
- Karl E. Wiegers, Software Requirements Specification Template, 1999.
- Dokumentasi Flutter 3.x – https://flutter.dev/docs
- Dokumentasi Laravel 11 – https://laravel.com/docs/11.x
- Midtrans Payment Gateway API Documentation – https://api.midtrans.com
- n8n Workflow Automation Documentation – https://docs.n8n.io
- MinIO Object Storage Documentation – https://min.io/docs

---

## 2. Overall Description

### 2.1 Product Perspective

TailoriX merupakan platform baru yang berdiri sendiri (new, self-contained product), bukan merupakan bagian dari sistem yang lebih besar. Platform ini terdiri dari dua aplikasi mobile (untuk pelanggan dan penjahit) dan satu backend API yang terpusat, dilengkapi dengan layanan ML untuk estimasi harga.

Sistem TailoriX berinteraksi dengan komponen eksternal berikut:
- Midtrans Payment Gateway (pemrosesan pembayaran)
- SendGrid (notifikasi email)
- Twilio (notifikasi WhatsApp)
- Google OAuth (autentikasi pihak ketiga)
- MinIO Object Storage (penyimpanan foto)

### 2.2 Product Functions

Fungsi-fungsi utama yang harus disediakan oleh TailoriX:

- **F-01**: Autentikasi & Manajemen Akun – registrasi, login, kelola profil.
- **F-02**: Pencarian & Pemilihan Penjahit – cari berdasarkan lokasi, filter, profil.
- **F-03**: Pemesanan Jasa Permak – buat pesanan dengan foto dan deskripsi.
- **F-04**: Estimasi Harga Otomatis (ML) – analisis foto dan berikan estimasi harga.
- **F-05**: Pembayaran Digital – integrasi Midtrans, DP, dan pelunasan.
- **F-06**: Tracking Status Pesanan – pantau status real-time dan notifikasi.
- **F-07**: Ulasan & Rating – sistem review dua arah setelah pesanan selesai.

### 2.3 User Classes and Characteristics

Terdapat tiga kelas pengguna utama dalam sistem TailoriX:

#### Pelanggan (Customer)
- Pengguna umum yang mencari jasa permak baju.
- Tingkat keahlian teknis beragam; sebagian besar pengguna smartphone dengan literasi digital menengah.
- Frekuensi penggunaan: insidental (saat butuh permak).
- Merupakan kelas pengguna paling penting untuk kepuasan.

#### Penjahit Mitra (Tailor)
- Penyedia jasa permak yang mendaftar sebagai mitra.
- Tingkat keahlian teknis rendah hingga menengah; memerlukan antarmuka yang sederhana.
- Frekuensi penggunaan: harian (menerima dan mengelola pesanan).

#### Admin Platform
- Pengelola platform TailoriX.
- Tingkat keahlian teknis tinggi.
- Mengelola moderasi konten, verifikasi mitra, dan laporan analitik.

### 2.4 Operating Environment

Lingkungan operasional sistem TailoriX:

| Komponen | Spesifikasi |
|----------|-------------|
| Mobile App | Android 8.0 (API Level 26)+; iOS 13.0+; Flutter 3.x |
| Backend API | Ubuntu 22.04 LTS, PHP 8.3, Laravel 11, MySQL 8.0, Redis 7 |
| ML Service | Python 3.11, FastAPI, TensorFlow/PyTorch, Docker container |
| Workflow Engine | n8n self-hosted dalam Docker container |
| Object Storage | MinIO (S3-compatible) dalam Docker container |
| Deployment | Docker Compose (dev), Docker Swarm/Kubernetes (production) |
| Koneksi | Memerlukan koneksi internet aktif untuk semua fitur utama |

### 2.5 Design and Implementation Constraints

- Platform mobile hanya Android dan iOS menggunakan Flutter; tidak ada versi web untuk pelanggan pada v1.0.
- Pembayaran hanya melalui Midtrans; COD tidak didukung pada v1.0.
- Layanan pickup/delivery hanya dalam radius yang ditentukan penjahit; tidak ada integrasi logistik pihak ketiga.
- Fitur ML estimasi harga memerlukan koneksi internet aktif; tidak berjalan offline.
- Data pengguna disimpan di server Indonesia untuk memenuhi regulasi UU PDP (Perlindungan Data Pribadi).
- Bahasa antarmuka hanya Bahasa Indonesia pada v1.0.
- Semua komunikasi antar layanan menggunakan HTTPS dengan enkripsi TLS 1.2+.

### 2.6 User Documentation

- In-app onboarding guide: tutorial interaktif saat pertama kali membuka aplikasi.
- FAQ & Help Center: tersedia dalam aplikasi, dapat diakses melalui menu profil.
- Push notification guide: panduan singkat tentang pengaturan notifikasi.
- Panduan Penjahit Mitra: dokumen PDF yang dikirim saat onboarding mitra penjahit.

### 2.7 Assumptions and Dependencies

#### Asumsi:
- Pengguna memiliki smartphone dengan kamera yang berfungsi untuk mengambil/mengunggah foto pakaian.
- Penjahit mitra memiliki koneksi internet stabil untuk menerima dan mengelola pesanan.
- Model ML awal akan dilatih dengan dataset dummy; akurasi estimasi akan meningkat seiring bertambahnya data feedback.

#### Dependensi:
- **Midtrans**: ketersediaan layanan payment gateway. Gangguan Midtrans akan menghambat proses pembayaran.
- **Google OAuth**: digunakan untuk opsi login Google. Gangguan akan menonaktifkan fitur login Google.
- **Twilio/SendGrid**: digunakan untuk notifikasi. Gangguan akan menghambat pengiriman notifikasi.
- **MinIO**: penyimpanan foto. Gangguan akan menghambat upload dan akses foto pakaian.

---

## 3. External Interface Requirements

### 3.1 User Interfaces

Antarmuka pengguna TailoriX dirancang menggunakan Flutter dengan mengacu pada Material Design 3 dan prinsip Human Interface Guidelines (HIG) untuk iOS. Karakteristik utama:

- Navigasi utama menggunakan Bottom Navigation Bar dengan maksimal 5 item.
- Setiap layar memiliki tombol aksi utama yang jelas dan konsisten.
- Layar pemuatan menggunakan skeleton loading (bukan spinner) untuk pengalaman yang lebih baik.
- Pesan error ditampilkan secara inline di dekat input yang bermasalah.
- Dukungan dark mode mengikuti preferensi sistem operasi.
- Ukuran tap target minimum 48x48dp sesuai standar aksesibilitas.

**Layar utama yang diperlukan:**
Splash/Onboarding, Login/Register, Beranda, Cari Penjahit, Buat Pesanan, Detail Pesanan, Pembayaran, Riwayat Pesanan, Profil, dan Admin Panel (web).

### 3.2 Hardware Interfaces

- **Kamera**: akses kamera dan galeri foto untuk upload foto pakaian (menggunakan `flutter_image_picker`).
- **GPS/Lokasi**: akses lokasi perangkat untuk fitur pencarian penjahit berdasarkan jarak (menggunakan `geolocator`).
- **Storage**: akses penyimpanan lokal untuk cache gambar dan token autentikasi (`flutter_secure_storage`).
- **Push Notification**: akses Firebase Cloud Messaging (FCM) untuk notifikasi push.
- **Biometrik**: opsional, fingerprint/face ID untuk login cepat.

### 3.3 Software Interfaces

| Komponen | Versi | Fungsi | Protokol |
|----------|-------|--------|----------|
| Laravel API | 11.x | Business logic & REST API backend | HTTPS REST JSON |
| MySQL | 8.0 | Database relasional utama | MySQL Protocol |
| Redis | 7.x | Cache, session, job queue | Redis Protocol |
| ML Service (FastAPI) | Python 3.11 | Estimasi harga via Computer Vision | HTTP JSON (internal) |
| Midtrans Snap API | v2 | Payment gateway | HTTPS REST JSON |
| n8n | latest | Otomasi notifikasi & workflow | Webhook HTTP |
| MinIO (S3) | latest | Object storage foto & file | S3 SDK / HTTPS |
| Firebase FCM | v9 | Push notification mobile | HTTPS |
| Google OAuth 2.0 | v2 | Autentikasi Google login | OAuth 2.0 HTTPS |

### 3.4 Communications Interfaces

- **REST API**: semua komunikasi antara Mobile App dan Backend menggunakan HTTPS (TLS 1.2+), format JSON, dengan JWT Bearer Token di header Authorization.
- **Webhook Midtrans**: HTTPS POST callback dari Midtrans ke endpoint `/api/v1/payments/webhook` saat pembayaran berhasil/gagal.
- **Webhook n8n**: HTTPS POST dari Laravel API ke n8n saat event bisnis terjadi (pesanan baru, pembayaran sukses, perubahan status).
- **Email (SendGrid)**: protokol SMTP via SendGrid API untuk notifikasi email transaksional.
- **WhatsApp (Twilio)**: Twilio WhatsApp Business API untuk notifikasi via WhatsApp.
- **FCM (Firebase)**: push notification real-time ke perangkat mobile melalui Firebase Cloud Messaging.
- **Transfer rate**: tidak ada persyaratan khusus; koneksi 4G/LTE atau Wi-Fi sudah memadai.

---

## 4. System Features

Bagian ini mendefinisikan fitur-fitur fungsional sistem TailoriX secara detail, termasuk deskripsi, prioritas, alur stimulus/respons, dan kebutuhan fungsional spesifik.

### 4.1 F-01: Autentikasi & Manajemen Akun

#### 4.1.1 Description and Priority
Fitur ini memungkinkan pengguna (pelanggan, penjahit, dan admin) untuk mendaftar, masuk, mengelola profil, dan mengakhiri sesi di aplikasi TailoriX.  
**Prioritas: High**

#### 4.1.2 Stimulus/Response Sequences
- Pengguna membuka aplikasi → tampilkan layar login/register → pengguna mengisi form registrasi → sistem kirim OTP → pengguna verifikasi → akun aktif, masuk ke beranda.
- Pengguna memilih login Google → sistem redirect ke Google OAuth → Google return token → sistem buat/update akun → pengguna masuk beranda.
- Pengguna lupa password → klik 'Lupa Password' → isi email → sistem kirim link reset → pengguna klik link → isi password baru → password berhasil diubah.

#### 4.1.3 Functional Requirements
- **REQ-01-01**: Sistem harus mendukung registrasi dengan email atau nomor HP dan verifikasi OTP 6 digit.
- **REQ-01-02**: Sistem harus mendukung login dengan email/password dan Google OAuth 2.0.
- **REQ-01-03**: Pengguna dapat mengelola profil (nama, foto, alamat, nomor HP).
- **REQ-01-04**: Sistem harus mendukung reset password melalui link yang dikirim ke email.
- **REQ-01-05**: Sistem harus mendukung logout yang menginvalidasi JWT token di server.
- **REQ-01-06**: Pengguna dapat menghapus akun; data terkait dianonimkan sesuai kebijakan privasi.
- **REQ-01-07**: Token JWT memiliki masa berlaku 1 jam; refresh token berlaku 30 hari.

### 4.2 F-02: Pencarian & Pemilihan Penjahit

#### 4.2.1 Description and Priority
Fitur ini memungkinkan pelanggan mencari dan memilih penjahit mitra berdasarkan berbagai parameter seperti lokasi, kategori jasa, rating, dan harga.  
**Prioritas: High**

#### 4.2.2 Stimulus/Response Sequences
- Pelanggan buka halaman pencarian → izinkan akses lokasi → sistem tampilkan daftar penjahit terdekat → pelanggan terapkan filter → sistem perbarui daftar → pelanggan pilih penjahit → tampil profil lengkap.
- Pelanggan pilih tampilan map → tampil peta dengan pin penjahit → pelanggan tap pin → tampil info singkat → pelanggan tap 'Lihat Profil' → tampil profil lengkap.

#### 4.2.3 Functional Requirements
- **REQ-02-01**: Sistem menampilkan daftar penjahit berdasarkan jarak dari lokasi pengguna (radius dapat disesuaikan).
- **REQ-02-02**: Sistem mendukung filter: kategori jasa, rating minimum, dan rentang harga.
- **REQ-02-03**: Profil penjahit menampilkan: nama toko, foto, spesialisasi, rating agregat, ulasan, portofolio, dan status ketersediaan.
- **REQ-02-04**: Sistem mendukung tampilan peta (map view) dengan marker lokasi penjahit.
- **REQ-02-05**: Pelanggan dapat menambahkan/menghapus penjahit dari daftar favorit.
- **REQ-02-06**: Hasil pencarian dipaginasi dengan maksimal 20 item per halaman.

### 4.3 F-03: Pemesanan Jasa Permak

#### 4.3.1 Description and Priority
Fitur ini memungkinkan pelanggan membuat pesanan jasa permak dengan mengunggah foto pakaian, mendeskripsikan kebutuhan, dan memilih opsi pengiriman.  
**Prioritas: High**

#### 4.3.2 Stimulus/Response Sequences
- Pelanggan pilih penjahit → klik 'Pesan Sekarang' → isi form pesanan (foto, deskripsi, kategori, deadline) → sistem kirim ke ML Service untuk estimasi harga → tampilkan estimasi → pelanggan konfirmasi → pesanan dibuat, notifikasi dikirim ke penjahit.
- Penjahit terima notifikasi pesanan baru → buka detail pesanan → terima/tolak → jika terima, isi harga final → konfirmasi → pelanggan menerima notifikasi persetujuan.

#### 4.3.3 Functional Requirements
- **REQ-03-01**: Pelanggan dapat mengunggah maksimal 5 foto pakaian (format JPG/PNG, maks 5MB per foto).
- **REQ-03-02**: Pelanggan mengisi deskripsi kebutuhan permak dalam teks bebas (maks 500 karakter).
- **REQ-03-03**: Pelanggan memilih kategori jasa: ubah ukuran, ganti ritsleting, tambal, sulam, atau lainnya.
- **REQ-03-04**: Pelanggan dapat menentukan deadline pengerjaan dengan pemilih tanggal.
- **REQ-03-05**: Pelanggan memilih mode pengiriman: antar ke toko atau pickup oleh kurir mitra penjahit.
- **REQ-03-06**: Penjahit menerima notifikasi pesanan baru dan dapat menerima/menolak dalam 24 jam.
- **REQ-03-07**: Penjahit dapat menyesuaikan harga final (maks 20% di atas estimasi ML tanpa alasan; di atas 20% harus disertai catatan).

### 4.4 F-04: Estimasi Harga Otomatis (ML)

#### 4.4.1 Description and Priority
Fitur ini menggunakan model Machine Learning berbasis Computer Vision untuk menganalisis foto pakaian dan memberikan estimasi harga otomatis kepada pelanggan dan penjahit.  
**Prioritas: Medium-High**

#### 4.4.2 Stimulus/Response Sequences
- Pelanggan upload foto & isi deskripsi → sistem kirim data ke ML Service → ML Service analisis gambar & kategori → return estimasi harga (min-max) beserta confidence level → tampilkan ke pelanggan.

#### 4.4.3 Functional Requirements
- **REQ-04-01**: ML Service menganalisis foto pakaian menggunakan model Computer Vision untuk mengidentifikasi jenis pakaian dan tingkat kerusakan/perubahan yang diperlukan.
- **REQ-04-02**: Sistem menampilkan estimasi harga dalam rentang (min-max) beserta confidence level kepada pelanggan.
- **REQ-04-03**: Penjahit dapat menyesuaikan harga final dari estimasi ML.
- **REQ-04-04**: Sistem menyimpan riwayat estimasi dan harga final untuk retraining model.
- **REQ-04-05**: Waktu respons estimasi ML tidak boleh melebihi 10 detik dalam kondisi normal.
- **REQ-04-06**: Jika ML Service tidak tersedia, sistem menampilkan pesan error dan meminta harga manual dari penjahit.

### 4.5 F-05: Pembayaran Digital

#### 4.5.1 Description and Priority
Fitur ini memungkinkan pelanggan melakukan pembayaran secara digital melalui berbagai metode yang terintegrasi dengan Midtrans payment gateway, termasuk sistem DP dan pelunasan.  
**Prioritas: High**

#### 4.5.2 Stimulus/Response Sequences
- Penjahit terima pesanan → pelanggan diarahkan ke halaman pembayaran → pilih metode → Midtrans tampilkan payment page → pelanggan selesaikan pembayaran → Midtrans kirim webhook → sistem update status → konfirmasi ke kedua belah pihak.

#### 4.5.3 Functional Requirements
- **REQ-05-01**: Sistem mengintegrasikan Midtrans Snap API untuk pemrosesan pembayaran.
- **REQ-05-02**: Metode pembayaran yang didukung: transfer bank (BCA, BNI, BRI, Mandiri), e-wallet (GoPay, OVO, DANA), dan virtual account.
- **REQ-05-03**: Sistem mendukung pembayaran DP (50% dari harga final) dan pelunasan setelah pesanan selesai.
- **REQ-05-04**: Sistem menghasilkan invoice digital dan bukti pembayaran yang dapat diunduh.
- **REQ-05-05**: Sistem memproses refund otomatis jika pesanan dibatalkan sebelum penjahit memulai pengerjaan.
- **REQ-05-06**: Pembayaran harus dikonfirmasi dalam 24 jam setelah order dikonfirmasi penjahit; jika tidak, order otomatis dibatalkan.

### 4.6 F-06: Tracking Status Pesanan

#### 4.6.1 Description and Priority
Fitur ini memungkinkan pelanggan dan penjahit memantau status pesanan secara real-time, berkomunikasi melalui in-app chat, dan menerima notifikasi otomatis setiap perubahan status.  
**Prioritas: High**

#### 4.6.2 Stimulus/Response Sequences
- Penjahit update status pesanan → sistem catat timestamp & kirim event ke n8n → n8n trigger push notification ke pelanggan & email/WhatsApp → pelanggan lihat update di timeline pesanan.

#### 4.6.3 Functional Requirements
- **REQ-06-01**: Status pesanan terdiri dari 5 tahap: Menunggu Konfirmasi → Dikonfirmasi → Proses Permak → Siap Diambil → Selesai.
- **REQ-06-02**: Setiap perubahan status memicu push notification real-time ke pelanggan.
- **REQ-06-03**: Sistem menampilkan timeline visual progres pengerjaan dengan timestamp setiap tahap.
- **REQ-06-04**: Pelanggan dapat menghubungi penjahit melalui in-app chat (teks dan foto).
- **REQ-06-05**: n8n mengirimkan notifikasi otomatis via email (SendGrid) dan WhatsApp (Twilio) untuk setiap perubahan status penting.
- **REQ-06-06**: Riwayat chat disimpan selama 90 hari setelah pesanan selesai.

### 4.7 F-07: Ulasan & Rating

#### 4.7.1 Description and Priority
Fitur ini memungkinkan pelanggan memberikan ulasan dan rating kepada penjahit setelah pesanan selesai, serta memungkinkan penjahit membalas ulasan tersebut.  
**Prioritas: Medium**

#### 4.7.2 Stimulus/Response Sequences
- Pesanan berstatus 'Selesai' → sistem kirim push notification ke pelanggan untuk memberikan ulasan → pelanggan isi rating (1-5 bintang) & teks ulasan & foto opsional → submit → ulasan tampil di profil penjahit.

#### 4.7.3 Functional Requirements
- **REQ-07-01**: Pelanggan dapat memberikan rating bintang 1-5 dan ulasan teks (maks 300 karakter) setelah pesanan selesai.
- **REQ-07-02**: Pelanggan dapat mengunggah foto hasil permak bersamaan dengan ulasan (maks 3 foto).
- **REQ-07-03**: Penjahit dapat memberikan balasan ulasan satu kali (maks 200 karakter).
- **REQ-07-04**: Sistem menghitung rating agregat penjahit berdasarkan rata-rata semua ulasan.
- **REQ-07-05**: Admin dapat memoderasi ulasan yang dilaporkan; ulasan yang melanggar kebijakan dapat disembunyikan.
- **REQ-07-06**: Ulasan dapat diedit oleh pelanggan dalam waktu 7 hari setelah dikirim.

---

## 5. Other Nonfunctional Requirements

### 5.1 Performance Requirements

- Waktu respons API untuk operasi CRUD standar: ≤ 500ms pada beban normal (< 1000 concurrent users).
- Waktu respons estimasi ML: ≤ 10 detik per request.
- Throughput sistem: minimal 100 transaksi per menit pada kondisi puncak.
- Waktu loading halaman utama aplikasi mobile: ≤ 2 detik pada koneksi 4G.
- Database query time: ≤ 200ms untuk query yang tidak melibatkan ML.
- Uptime sistem: 99.5% per bulan (downtime maksimal ~3.6 jam/bulan).

### 5.2 Safety Requirements

- Sistem harus mencegah double-payment: setiap order hanya dapat diproses satu transaksi aktif pada satu waktu.
- Sistem harus memiliki mekanisme rollback otomatis jika transaksi pembayaran gagal di tengah proses.
- Data foto pakaian tidak boleh digunakan untuk tujuan selain estimasi harga dan portofolio penjahit.
- Sistem harus memiliki logging audit trail untuk semua perubahan status pesanan dan transaksi keuangan.

### 5.3 Security Requirements

- Semua komunikasi menggunakan HTTPS dengan TLS 1.2 atau lebih tinggi.
- Password disimpan menggunakan bcrypt dengan salt (cost factor minimal 12).
- JWT token menggunakan algoritma RS256; private key disimpan secara aman di server.
- API dilindungi dengan rate limiting: maksimal 60 request per menit per IP untuk endpoint publik; 120 untuk endpoint terautentikasi.
- Data sensitif pengguna (nomor HP, alamat) dienkripsi di database menggunakan AES-256.
- Webhook Midtrans diverifikasi menggunakan signature key sebelum diproses.
- Autentikasi dua faktor (2FA) opsional untuk pelanggan; wajib untuk admin.
- OWASP Top 10 menjadi acuan dalam pengembangan untuk mencegah SQL Injection, XSS, CSRF, dan vulnerability umum lainnya.

### 5.4 Software Quality Attributes

- **Usability**: antarmuka harus dapat dipelajari oleh pengguna baru dalam maksimal 5 menit; user error rate < 5%.
- **Reliability**: MTBF (Mean Time Between Failures) minimal 720 jam; recovery dari crash < 30 detik.
- **Maintainability**: codebase mengikuti PSR-12 (PHP) dan Dart Style Guide; coverage unit test minimal 70%.
- **Portability**: aplikasi mobile berjalan di Android 8.0+ dan iOS 13.0+ tanpa modifikasi.
- **Scalability**: arsitektur mendukung horizontal scaling; load balancer dapat menambah instance API tanpa downtime.
- **Testability**: setiap modul memiliki unit test dan integration test; CI/CD pipeline berjalan otomatis.

### 5.5 Business Rules

- Penjahit harus terverifikasi (KTP + foto toko) oleh admin sebelum dapat menerima pesanan.
- Komisi platform TailoriX: 10% dari harga final setiap transaksi yang berhasil.
- Pelanggan hanya dapat membatalkan pesanan sebelum penjahit memulai pengerjaan; setelah itu hanya dapat mengajukan dispute.
- Penjahit yang memiliki rating di bawah 3.0 selama 30 hari berturut-turut akan mendapatkan peringatan; di bawah 2.5 selama 60 hari akan dinonaktifkan sementara.
- Dana DP yang dibayarkan tidak dapat di-refund jika pembatalan dilakukan oleh pelanggan setelah penjahit memulai pengerjaan.
- Satu akun email/nomor HP hanya dapat digunakan untuk satu akun (pelanggan ATAU penjahit, tidak keduanya).

---

## 6. Other Requirements

### 6.1 Database Requirements

- Database relasional MySQL 8.0 digunakan untuk menyimpan data utama (user, order, payment, review).
- Redis 7 digunakan untuk caching, session management, dan job queue.
- Foto dan file disimpan di MinIO (S3-compatible object storage), bukan di database relasional.
- Backup database dilakukan setiap hari pukul 02.00 WIB; retensi backup 30 hari.
- Database harus mendukung UTF-8 (utf8mb4) untuk mendukung karakter emoji dan bahasa Indonesia.

### 6.2 Internationalization Requirements

Pada versi 1.0, sistem hanya mendukung Bahasa Indonesia. Arsitektur sistem dirancang dengan mempertimbangkan kemungkinan penambahan bahasa lain di versi mendatang menggunakan Flutter's l10n package dan Laravel localization.

### 6.3 Legal Requirements

- Platform harus mematuhi Undang-Undang Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP) Indonesia.
- Syarat & Ketentuan serta Kebijakan Privasi harus ditampilkan dan disetujui pengguna saat registrasi.
- Platform harus mematuhi regulasi Bank Indonesia terkait transaksi digital (PBI No.23/6/PBI/2021).

### 6.4 Machine Learning Requirements
Bagian ini mendefinisikan kebutuhan spesifik untuk komponen kecerdasan buatan yang mendukung fitur F-04: Estimasi Harga Otomatis.

- Model Estimasi Harga: Menggunakan model Computer Vision (seperti CNN atau ViT) untuk menganalisis foto pakaian guna mengidentifikasi jenis pakaian dan tingkat kerumitan perbaikan.
- Deployment Service: ML service di-deploy sebagai REST API menggunakan FastAPI di dalam Docker container.
- Integrasi Sistem: API ML dikonsumsi secara internal oleh Laravel backend untuk memberikan rentang harga (min-max) kepada pelanggan secara real-time.
-  Workflow Otomasi: Data hasil estimasi dan feedback harga final dikirimkan ke engine n8n untuk pemantauan akurasi model secara berkala.
- Mekanisme Retraining: Model harus di-retrain secara berkala menggunakan riwayat estimasi dan harga final yang disimpan di database untuk meningkatkan akurasi confidence level.
- SLA Performa: Waktu respons inferensi model tidak boleh melebihi 10 detik per request untuk menjaga pengalaman pengguna.
- Fallback Mechanism: Jika ML service tidak tersedia (down), sistem harus mampu beralih ke mode input harga manual oleh penjahit.

---
## Appendix A: Glossary

| Istilah / Akronim | Definisi |
|------------------|----------|
| **SRS** | *Software Requirements Specification* – dokumen yang mendeskripsikan kebutuhan perangkat lunak secara lengkap, mencakup kebutuhan fungsional dan non-fungsional. |
| **TailoriX** | Nama platform digital yang dikembangkan untuk menyediakan layanan permak dan alterasi pakaian secara online. |
| **Permak Baju** | Layanan perbaikan, perubahan ukuran, atau modifikasi pakaian yang sudah ada agar sesuai dengan kebutuhan pengguna. |
| **JWT** | *JSON Web Token* – standar terbuka (RFC 7519) yang digunakan untuk transmisi informasi secara aman antar pihak dalam bentuk objek JSON, biasanya digunakan untuk autentikasi dan otorisasi. |
| **ML** | *Machine Learning* – cabang dari kecerdasan buatan (*Artificial Intelligence*) yang memungkinkan sistem belajar dari data dan meningkatkan performa tanpa diprogram secara eksplisit. |
| **n8n** | Platform *workflow automation* berbasis open-source yang digunakan untuk mengotomatisasi proses bisnis seperti notifikasi, integrasi sistem, dan alur kerja digital. |
| **Midtrans** | Payment gateway Indonesia yang mendukung berbagai metode pembayaran digital seperti transfer bank, e-wallet, kartu kredit, dan lainnya. |
| **DP** | *Down Payment* / Uang Muka – pembayaran awal sebagian dari total harga yang harus dibayar sebelum layanan diproses. |
| **MinIO** | Object storage server yang kompatibel dengan Amazon S3 API, digunakan untuk menyimpan file seperti foto, dokumen, dan media lainnya. |
| **OTP** | *One-Time Password* – kode sandi sekali pakai yang digunakan untuk proses verifikasi identitas pengguna secara aman. |
| **UMKM** | *Usaha Mikro, Kecil, dan Menengah* – kategori usaha di Indonesia yang diklasifikasikan berdasarkan skala modal dan omzet. |
| **REQ** | *Requirement* – kode identifikasi unik yang digunakan untuk menandai setiap kebutuhan fungsional dalam dokumen SRS. |
| **FCM** | *Firebase Cloud Messaging* – layanan dari Google yang digunakan untuk mengirim push notification ke aplikasi mobile maupun web. |
| **TBD** | *To Be Determined* – istilah yang menunjukkan bahwa suatu informasi belum ditentukan dan akan diputuskan di kemudian hari. |

---

## Appendix B: Analysis Models


**Use Case Diagram**

<img width="842" height="913" alt="use case" src="https://github.com/user-attachments/assets/c8ad23a4-1c8f-4dbd-8bf4-9bf6a64fd852" />

**Activity Diagram**

<img width="714" height="1600" alt="diagram activity" src="https://github.com/user-attachments/assets/afcb8a34-6a92-408d-ab0d-0e62f7165b9b" />

**Rancangan Database**

<img width="1162" height="1033" alt="Screenshot 2026-05-01 134203" src="https://github.com/user-attachments/assets/260835b8-3e71-4a7e-b6e2-46a5b518ae44" />

**Rancangan Arsitektur Sistem**

<img width="1600" height="879" alt="rancangan arsitektur sistem" src="https://github.com/user-attachments/assets/145b96b9-66aa-45a2-a41b-dc54ac8a11f7" />

**Rancangan Arsitektur Teknologi**

<img width="1536" height="929" alt="rancangan arsitektur teknologi" src="https://github.com/user-attachments/assets/de610e9f-2306-4b49-88aa-5dd690cb6870" />

**UI**

<img width="713" height="901" alt="WhatsApp Image 2026-04-26 at 15 29 30" src="https://github.com/user-attachments/assets/ed074ac1-aaa8-4b41-9b67-e0e2107a06ae" />
<img width="1168" height="680" alt="WhatsApp Image 2026-04-26 at 15 29 30 (1)" src="https://github.com/user-attachments/assets/02eb019c-e8b1-4b68-b8ab-846f8574a24e" />
<img width="1112" height="865" alt="WhatsApp Image 2026-04-26 at 15 29 31" src="https://github.com/user-attachments/assets/b9d78651-7f26-4c03-80c5-29fa6911bc1b" />

**Class Diagram**

<img width="1600" height="1018" alt="classdiagram" src="https://github.com/user-attachments/assets/312903ed-19d9-4a45-b3e8-17dbd9d25667" />

**Sequence Diagram**

<img width="1600" height="1493" alt="sequencediagram" src="https://github.com/user-attachments/assets/bbf9338b-0769-42c3-9219-479f0c35af39" />


**Component Diagram**

<img width="1600" height="1173" alt="componentdiagram" src="https://github.com/user-attachments/assets/f0f8b1c0-efc3-4bd4-b3de-4ee807c17a62" />

**Deployment Diagram**

<img width="1360" height="1349" alt="deploymentdiagram" src="https://github.com/user-attachments/assets/e9e30d4c-3617-433d-a720-fe89ec3066e1" />


---

## Appendix C: To Be Determined List

| No. | Item TBD | Keterangan |
|-----|----------|-----------|
| **1** | Spesifikasi dataset untuk training model ML estimasi harga | Akan ditentukan setelah konsultasi dengan tim Machine Learning dan penjahit mitra. |
| **2** | SLA (*Service Level Agreement*) dengan Midtrans untuk *settlement time* | Bergantung pada hasil negosiasi kontrak dengan pihak Midtrans. |
| **3** | Skema komisi dan disbursement ke penjahit mitra | Memerlukan finalisasi model bisnis bersama stakeholder. |
| **4** | Kebijakan *dispute resolution* antara pelanggan dan penjahit | Perlu konsultasi dan persetujuan dari tim legal. |
| **5** | Spesifikasi teknis fitur *in-app chat* (real-time WebSocket vs polling) | Akan diputuskan berdasarkan kapasitas server dan pertimbangan budget. |


---


