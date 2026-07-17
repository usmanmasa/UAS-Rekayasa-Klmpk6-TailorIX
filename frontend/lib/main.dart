import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/order_service.dart';
import 'services/push_notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final orderService = OrderService(apiClient);
  await apiClient.loadTokenFromStorage();

  // Global handler: jika backend merespon 401, pastikan token dihapus
  // dan arahkan user kembali ke halaman login (bersihkan stack).
  ApiClient.onUnauthenticated = () {
    final nav = PushNotificationService.navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authService: authService,
          orderService: orderService,
          apiClient: apiClient,
        ),
      ),
      (route) => false,
    );
  };

  runApp(TailorLXApp(
    authService: authService,
    orderService: orderService,
    apiClient: apiClient,
  ));
}

class TailorLXApp extends StatelessWidget {
  const TailorLXApp({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailorLX',
      debugShowCheckedModeBanner: false,
      navigatorKey: PushNotificationService.navigatorKey,
      theme: AppTheme.light,
      home: SplashScreen(
        authService: authService,
        orderService: orderService,
        apiClient: apiClient,
      ),
    );
  }
}
