import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/onboarding_prefs.dart';
import '../auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import 'welcome_screen.dart';

/// Layar pembuka TailorLX (Poin 2) — murni kosmetik/branding moment saat
/// aplikasi dibuka. Tidak melakukan panggilan API apa pun; hanya membaca
/// status "sudah lihat onboarding" dari penyimpanan lokal, lalu meneruskan
/// ke `OnboardingScreen` (kunjungan pertama) atau langsung `LoginScreen`
/// (kunjungan berikutnya). Jika layar ini dilewati sepenuhnya, aplikasi
/// tetap berfungsi penuh karena tujuan akhirnya selalu `LoginScreen`.
class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const SplashScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Durasi minimum splash agar tidak terasa "berkedip" di perangkat cepat,
    // sekaligus memberi waktu untuk pengecekan status onboarding di bawah.
    final minimumDelay = Future.delayed(const Duration(milliseconds: 1400));

    bool onboardingSeen = false;
    bool welcomeConsent = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingSeen = prefs.getBool(kOnboardingSeenKey) ?? false;
    } catch (_) {
      // ignore
    }
    try {
      welcomeConsent = await OnboardingPrefs.getWelcomeConsent();
    } catch (_) {
      welcomeConsent = false;
    }

    await minimumDelay;
    if (!mounted) {
      return;
    }

    Widget target;
    if (!onboardingSeen) {
      target = OnboardingScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
      );
    } else if (!welcomeConsent) {
      target = WelcomeScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
      );
    } else {
      target = LoginScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Latar indigo gelap dipakai khusus di sini (berbeda dari `chalk` di
    // seluruh app) supaya splash terasa seperti "brand moment" atelier,
    // baru berpindah ke tema terang saat masuk ke onboarding/login.
    return Scaffold(
      backgroundColor: AppColors.indigoDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.indigoLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.6),
              ),
              child: const Text('✂️', style: TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 22),
            Text(
              'TailorLX',
              style: GoogleFonts.fraunces(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PERMAK & JAHIT, SEPENUH HATI',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
