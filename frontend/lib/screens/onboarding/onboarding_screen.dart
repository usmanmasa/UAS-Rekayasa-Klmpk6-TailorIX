import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';
import '../auth/login_screen.dart';

/// Kunci SharedPreferences untuk menandai bahwa pengguna sudah pernah
/// melihat layar onboarding, supaya tidak ditampilkan berulang setiap
/// kali aplikasi dibuka (lihat `SplashScreen`).
const String kOnboardingSeenKey = 'onboarding_seen';

class _OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  const _OnboardingPage(
      {required this.emoji, required this.title, required this.description});
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    emoji: '🧵',
    title: 'Temukan Penjahit Terpercaya',
    description:
        'Jelajahi mitra penjahit di sekitarmu, bandingkan kategori jasa permak, rating, dan harga sebelum memesan.',
  ),
  _OnboardingPage(
    emoji: '📦',
    title: 'Pesan & Pantau Progresnya',
    description:
        'Ajukan pesanan permak lengkap dengan foto, dapatkan estimasi harga, lalu lacak status pengerjaan secara real-time.',
  ),
  _OnboardingPage(
    emoji: '💬',
    title: 'Chat & Bayar dengan Aman',
    description:
        'Diskusikan detail permak langsung dengan penjahit, lalu selesaikan pembayaran dengan aman lewat aplikasi.',
  ),
];

/// Layar onboarding — hanya muncul sekali di kunjungan pertama (Poin 2).
/// Bersifat kosmetik/pelengkap: melewati layar ini tidak mengganggu alur
/// bisnis inti karena pengguna tetap berakhir di `LoginScreen`.
class OnboardingScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const OnboardingScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingSeenKey, true);
    } catch (_) {
      // Jika penyimpanan lokal gagal (mis. platform belum siap), abaikan saja —
      // onboarding cukup ditampilkan lagi di kunjungan berikutnya, tidak fatal.
    }
    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authService: widget.authService,
          orderService: widget.orderService,
          apiClient: widget.apiClient,
        ),
      ),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.chalk,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            return SizedBox(
              width: constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : size.width,
              height: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : size.height,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                      child: TextButton(
                        onPressed: isLast ? null : _finish,
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: isLast
                                ? Colors.transparent
                                : AppColors.charcoalSoft,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final page = _pages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 132,
                                height: 132,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.goldPale,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.gold.withAlpha(102),
                                      width: 1.4),
                                ),
                                child: Text(page.emoji,
                                    style: const TextStyle(fontSize: 52)),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        fontFamily:
                                            GoogleFonts.fraunces().fontFamily),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.charcoalSoft,
                                    height: 1.6),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: StitchDivider(verticalMargin: 8),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: List.generate(_pages.length, (i) {
                              final active = i == _page;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.only(right: 6),
                                width: active ? 20 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.indigo
                                      : AppColors.linenDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(88, 44)),
                            child: Text(isLast ? 'Mulai' : 'Lanjut'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
