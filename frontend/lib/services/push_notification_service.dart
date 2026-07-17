import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'order_service.dart';
import 'tailor_service.dart';
import '../screens/order/order_tracking_screen.dart';
import '../screens/tailor_panel/tailor_order_detail_screen.dart';

/// Dipanggil oleh OS saat push masuk ketika app di background/terminated.
/// WAJIB top-level function (bukan method kelas/closure) + anotasi
/// `@pragma('vm:entry-point')` supaya Flutter engine bisa membangunkan
/// isolate terpisah untuk menjalankannya. Didaftarkan sekali di `main()`
/// lewat `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`
/// — SEBELUM `runApp()`.
///
/// Isolate ini terpisah dari isolate utama aplikasi (tidak ada state/widget
/// tree di sini), jadi kita hanya bisa melakukan hal-hal ringan & stateless
/// seperti logging. Menampilkan notifikasi ke system tray untuk pesan
/// bertipe "notification" sudah otomatis dilakukan oleh OS — handler ini
/// dipakai untuk kasus seperti data-only message atau side-effect ringan
/// (mis. sinkronisasi badge count), yang tidak kita perlukan saat ini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Sengaja dibiarkan minimal: OS sudah menampilkan notifikasi dari payload
  // `notification` secara otomatis saat app di background/terminated.
  // Tap pada notifikasi tersebut ditangani lewat `getInitialMessage()` /
  // `onMessageOpenedApp` di bawah, bukan di sini.
}

/// F-06: Notifikasi Otomatis lewat Firebase Cloud Messaging.
///
/// Sebelum dipakai, jalankan `flutterfire configure` (paket `flutterfire_cli`)
/// di root project Flutter untuk menghasilkan `lib/firebase_options.dart`,
/// lalu panggil `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
/// di `main()` sebelum `runApp`. Tanpa langkah itu, semua method di bawah
/// gagal dengan aman (dibungkus try-catch) sehingga aplikasi tetap berjalan
/// normal tanpa notifikasi push.
///
/// Tiga arsitektur FCM yang ditangani kelas ini:
/// 1. Foreground (`FirebaseMessaging.onMessage`) — app sedang dibuka, OS
///    TIDAK otomatis menampilkan banner, jadi kita tampilkan sendiri lewat
///    `flutter_local_notifications`.
/// 2. Background/terminated (`onBackgroundMessage`) — lihat
///    [firebaseMessagingBackgroundHandler] di atas.
/// 3. Tap notifikasi (`onMessageOpenedApp` + `getInitialMessage`) — baca
///    payload `data` (`order_id`, `type`) lalu navigasi ke halaman pesanan
///    yang sesuai lewat [navigatorKey], bukan cuma buka halaman default.
class PushNotificationService {
  /// Dipasang di `MaterialApp(navigatorKey: ...)` (lihat main.dart) supaya
  /// kelas static ini bisa melakukan navigasi tanpa butuh `BuildContext`
  /// dari widget tree (notifikasi bisa masuk kapan saja, termasuk saat
  /// tidak ada layar yang "aktif" memegang context yang relevan).
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Diisi oleh `LoginScreen` setelah login berhasil (lihat `_goToRoleHome`),
  /// karena tujuan navigasi tap-notifikasi berbeda tergantung role
  /// (`OrderTrackingScreen` untuk pelanggan, `TailorOrderDetailScreen`
  /// untuk penjahit). Token FCM hanya terdaftar ke backend setelah login,
  /// jadi handler ini juga baru mungkin dipakai setelah login.
  static void Function(int orderId)? onOrderTap;

  /// Dipanggil dari `LoginScreen`/`RegisterScreen` setelah autentikasi
  /// berhasil. Membangun & mendaftarkan [onOrderTap] di satu tempat supaya
  /// kedua layar tersebut tidak perlu masing-masing mengimpor
  /// `OrderTrackingScreen`/`TailorOrderDetailScreen` sendiri.
  static void configureOrderTapHandler({
    required ApiClient apiClient,
    required OrderService orderService,
    required String role,
    required int userId,
  }) {
    onOrderTap = (orderId) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => role == 'penjahit'
              ? TailorOrderDetailScreen(
                  tailorService: TailorService(apiClient),
                  orderService: orderService,
                  apiClient: apiClient,
                  orderId: orderId,
                  currentUserId: userId,
                )
              : OrderTrackingScreen(
                  orderService: orderService,
                  apiClient: apiClient,
                  orderId: orderId,
                  currentUserId: userId,
                ),
        ),
      );
    };
  }

  /// Dipanggil saat logout (lihat `ProfileScreen`) supaya notifikasi yang
  /// (secara teori) masih bisa masuk sesudahnya tidak mencoba navigasi
  /// pakai `apiClient`/`orderService` milik sesi yang sudah berakhir.
  static void clearOrderTapHandler() {
    onOrderTap = null;
  }

  static bool _foregroundListenersReady = false;

  /// Minta izin notifikasi (terutama untuk iOS) lalu ambil FCM token dan
  /// kirim ke backend lewat `PUT /api/profile` agar bisa dipakai mengirim
  /// push notification (terima pesanan baru, perubahan status, chat, dst).
  static Future<void> registerToken(AuthService authService) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await authService.updateProfile({'fcm_token': token});
      }

      // Token bisa berubah (reinstall, clear data, dll), pastikan tetap
      // sinkron dengan backend setiap kali berubah.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        authService.updateProfile({'fcm_token': newToken});
      });

      await _ensureForegroundListeners();
    } catch (e) {
      // Firebase belum dikonfigurasi (firebase_options.dart belum ada) atau
      // platform belum disetup; abaikan agar tidak mengganggu alur login.
    }
  }

  /// Setup local notifications (untuk foreground) + listener tap. Aman
  /// dipanggil berkali-kali (hanya jalan sekali per lifetime aplikasi).
  static Future<void> _ensureForegroundListeners() async {
    if (_foregroundListenersReady) return;
    _foregroundListenersReady = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      // Tap pada notifikasi lokal (muncul saat app foreground).
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      'tailorlx_default',
      'Notifikasi TailorLX',
      description: 'Update pesanan, pembayaran, dan pesan chat',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 1. Foreground: tampilkan manual lewat local notification.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'tailorlx_default',
            'Notifikasi TailorLX',
            channelDescription: 'Update pesanan, pembayaran, dan pesan chat',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // 3a. Tap notifikasi saat app di background (bukan terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleDataPayload(message.data);
    });

    // 3b. App dibuka dari kondisi terminated lewat tap notifikasi.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleDataPayload(initialMessage.data);
    }
  }

  static void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleDataPayload(data);
    } catch (_) {
      // Payload tidak valid, abaikan saja daripada crash.
    }
  }

  static void _handleDataPayload(Map<String, dynamic> data) {
    // Backend mengirim `order_id` untuk tipe 'order_status' & 'chat' (lihat
    // `NotificationService` di Laravel) — keduanya cukup diarahkan ke
    // halaman detail/tracking pesanan yang sama.
    final rawOrderId = data['order_id'];
    final orderId = rawOrderId is String ? int.tryParse(rawOrderId) : rawOrderId as int?;
    if (orderId == null) return;

    final handler = onOrderTap;
    if (handler != null) {
      handler(orderId);
    }
    // Jika belum ada handler terdaftar (mis. app baru dibuka dari kondisi
    // terminated dan user belum login), payload ini otomatis hilang —
    // wajar karena token sesi (Bearer) juga tidak persisten lintas restart
    // (lihat `ApiClient`), jadi user akan diarahkan login dulu seperti biasa.
  }
}
