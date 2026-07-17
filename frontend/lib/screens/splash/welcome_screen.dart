import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../services/onboarding_prefs.dart';

class WelcomeScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const WelcomeScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text('TailorLX', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('PERMAK & JAHIT, SEPENUH HATI', style: TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 18),
              const Center(child: Icon(Icons.content_cut, size: 72, color: AppColors.indigo)),
              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Pelajari tentang kami', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text(
                          'TailorLX membantu Anda menemukan penjahit terpercaya di sekitar, memesan jasa permak dengan foto dan estimasi harga, melacak progres pengerjaan, serta memberikan ulasan setelah pesanan selesai. Kami berkomitmen menjaga kualitas, keamanan data, dan transparansi harga.'),
                      SizedBox(height: 12),
                      Text('Hak dan kewajiban pengguna:', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('- Pastikan foto dan deskripsi pesanan akurat.'),
                      Text('- Tinjau estimasi harga sebelum menyetujui.'),
                      Text('- Beri ulasan jujur setelah pesanan selesai.'),
                      SizedBox(height: 12),
                      Text('Privasi & data:', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('Data Anda hanya digunakan untuk keperluan pemesanan dan notifikasi; tidak dibagikan ke pihak ketiga tanpa izin.'),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: const Text('Saya telah membaca dan menyetujui informasi di atas'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _agreed
                                ? () async {
                                    // Simpan persetujuan sebelum melanjutkan ke Login
                                    final navigator = Navigator.of(context);
                                    try {
                                      await OnboardingPrefs.setWelcomeConsent(true);
                                    } catch (_) {}
                                    if (!mounted) {
                                      return;
                                    }
                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(
                                          authService: widget.authService,
                                          orderService: widget.orderService,
                                          apiClient: widget.apiClient,
                                        ),
                                      ),
                                    );
                                  }
                    : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Lanjut ke Login'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
