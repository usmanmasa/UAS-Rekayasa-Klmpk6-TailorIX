import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'models/order.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'screens/admin_users_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/customer_waiting_screen.dart';
import 'screens/tailor_order_confirmation_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/review_screen.dart';
import 'screens/role_based_app_shell.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tailor_detail_screen.dart';
import 'screens/tailor_map_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FcmService.initialize();
  }
  
  await _initializeFirebaseMessaging();
  await ApiService.initialize();
  runApp(const ProviderScope(child: TailoriXApp()));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _initializeFirebaseMessaging() async {
  if (kIsWeb) return;

  await FcmService.saveTokenToBackend();

  FcmService.listenOnTokenRefresh();

  FcmService.listenOnForegroundMessage((message) {
    final title = message.notification?.title ?? 'Notifikasi TailoriX';
    final body = message.notification?.body ?? 'Anda menerima pesan baru.';
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title\n$body')),
      );
    }
  });

  FcmService.listenOnMessageOpenedApp(_handleNotificationOpened);

  final initialMessage = await FcmService.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationOpened(initialMessage);
  }
}

Future<void> _handleNotificationOpened(dynamic message) async {
  if (message == null) return;
  
  final orderId = message.data['order_id']?.toString();
  if (orderId == null || orderId.isEmpty) {
    return;
  }

  final type = message.data['type']?.toString();
  final route = (type == 'order_confirmed' || type == 'order_accepted')
      ? '/order-detail'
      : (type == 'order_waiting' || type == 'waiting_confirmation')
          ? '/customer-waiting'
          : (type == 'order_new' || type == 'tailor_confirm')
              ? '/tailor-order-confirmation'
              : '/order-detail';

  try {
    final order = await ApiService.fetchOrderDetail(orderId);
    navigatorKey.currentState?.pushNamed(route, arguments: order);
  } catch (_) {
    // ignore; navigation only when order detail berhasil diambil
  }
}

class TailoriXApp extends StatelessWidget {
  const TailoriXApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailoriX',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.grey[900],
          iconTheme: IconThemeData(color: Colors.grey[900]),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/app': (_) => const RoleBasedAppShell(),
        '/search': (_) => const SearchScreen(),
        '/tailor-detail': (_) => const TailorDetailScreen(),
        '/tailor-map': (_) => const TailorMapScreen(),
        '/order-form': (_) => const OrderFormScreen(),
        '/customer-waiting': (context) {
          final order = ModalRoute.of(context)!.settings.arguments as Order;
          return CustomerWaitingScreen(order: order);
        },
        '/tailor-order-confirmation': (context) {
          final order = ModalRoute.of(context)!.settings.arguments as Order;
          return TailorOrderConfirmationScreen(order: order);
        },
        '/order-detail': (_) => const OrderDetailScreen(),
        '/order-history': (_) => const OrderHistoryScreen(),
        '/admin-orders': (_) => const OrderHistoryScreen(),
        '/admin-users': (_) => const AdminUsersScreen(),
        '/payment': (_) => const PaymentScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/review': (_) => const ReviewScreen(),
      },
    );
  }
}
