import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/review_screen.dart';
import 'screens/role_based_app_shell.dart';
import 'screens/search_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tailor_detail_screen.dart';

void main() {
  runApp(const TailoriXApp());
}

class TailoriXApp extends StatelessWidget {
  const TailoriXApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailoriX',
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
        '/order-form': (_) => const OrderFormScreen(),
        '/order-detail': (_) => const OrderDetailScreen(),
        '/order-history': (_) => const OrderHistoryScreen(),
        '/admin-orders': (_) => const OrderHistoryScreen(),
        '/payment': (_) => const PaymentScreen(),
        '/review': (_) => const ReviewScreen(),
      },
    );
  }
}
