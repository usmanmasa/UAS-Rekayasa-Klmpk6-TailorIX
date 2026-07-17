import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/tailor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';
import '../tailor/customer_home.dart';
import '../tailor_panel/tailor_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Modul F-01: Login email & password
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;

  void _goToRoleHome(dynamic user) {
    // F-06: daftarkan token FCM perangkat ini ke backend agar bisa menerima
    // notifikasi (pesanan masuk, perubahan status, chat baru, dst), lalu
    // siapkan tujuan navigasi saat notifikasi push itu di-tap (tidak cukup
    // cuma buka app ke halaman default — harus langsung ke pesanan terkait).
    PushNotificationService.registerToken(widget.authService);
    PushNotificationService.configureOrderTapHandler(
      apiClient: widget.apiClient,
      orderService: widget.orderService,
      role: user.role,
      userId: user.id,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.role == 'penjahit'
            ? TailorHomeScreen(
                authService: widget.authService,
                orderService: widget.orderService,
                tailorService: TailorService(widget.apiClient),
                apiClient: widget.apiClient,
                currentUserId: user.id,
              )
            : CustomerHome(
                authService: widget.authService,
                orderService: widget.orderService,
                apiClient: widget.apiClient,
                currentUserId: user.id,
              ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await widget.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      _goToRoleHome(user);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            children: [
              Text('SELAMAT DATANG',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: AppColors.gold)),
              const SizedBox(height: 6),
              Text('Masuk ke TailorLX',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: GoogleFonts.fraunces().fontFamily)),
              const SizedBox(height: 8),
              const Text(
                'Lanjutkan pesanan permak & jahit kamu, atau kelola toko sebagai mitra penjahit.',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.charcoalSoft, height: 1.5),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', hintText: 'nama@email.com'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(() {
                      _passwordVisible = !_passwordVisible;
                    }),
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (v) =>
                    v == null || v.length < 8 ? 'Minimal 8 karakter' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                            authService: widget.authService)),
                  ),
                  child: const Text('Lupa kata sandi?'),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Masuk'),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(
                        authService: widget.authService,
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                      ),
                    ),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.charcoalSoft),
                      children: [
                        TextSpan(text: 'Belum punya akun? '),
                        TextSpan(
                            text: 'Daftar di sini',
                            style: TextStyle(
                                color: AppColors.indigo,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const StitchDivider(),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(
                          authService: widget.authService,
                          orderService: widget.orderService,
                          apiClient: widget.apiClient,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.linenDark),
                      ),
                      child: const Column(children: [
                        Text('🙋', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 6),
                        Text('Saya Pelanggan',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(
                          authService: widget.authService,
                          orderService: widget.orderService,
                          apiClient: widget.apiClient,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold, width: 1.6),
                      ),
                      child: const Column(children: [
                        Text('✂️', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 6),
                        Text('Saya Mitra Penjahit',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
