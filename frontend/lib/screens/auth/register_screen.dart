import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/tailor_service.dart';
import '../../theme/app_colors.dart';
import '../tailor/customer_home.dart';
import '../tailor_panel/tailor_home_screen.dart';

/// Modul F-01: Registrasi akun
class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'pelanggan';
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await widget.authService.register(
        name: _nameController.text,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
        role: _role,
      );
      if (!mounted) {
        return;
      }
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrasi gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('Daftar sebagai',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.charcoalSoft, letterSpacing: .6)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _RoleCard(emoji: '🙋', label: 'Pelanggan', value: 'pelanggan', groupValue: _role, onTap: (v) => setState(() => _role = v))),
                const SizedBox(width: 10),
                Expanded(child: _RoleCard(emoji: '✂️', label: 'Mitra Penjahit', value: 'penjahit', groupValue: _role, onTap: (v) => setState(() => _role = v))),
              ]),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', hintText: 'Sesuai KTP'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@email.com'),
                validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  helperText: 'Minimal 8 karakter, kombinasi huruf & angka',
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() {
                      _passwordVisible = !_passwordVisible;
                    }),
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (v) => v == null || v.length < 8 ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  suffixIcon: IconButton(
                    icon: Icon(_confirmVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() {
                      _confirmVisible = !_confirmVisible;
                    }),
                  ),
                ),
                obscureText: !_confirmVisible,
                validator: (v) => v != _passwordController.text ? 'Kata sandi tidak sama' : null,
              ),
              const SizedBox(height: 22),
              const Row(children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dengan mendaftar, kamu menyetujui Syarat & Ketentuan serta Kebijakan Privasi TailorLX.',
                    style: TextStyle(fontSize: 11.3, color: AppColors.charcoalSoft, height: 1.5),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12.5, color: AppColors.charcoalSoft),
                      children: [
                        TextSpan(text: 'Sudah punya akun? '),
                        TextSpan(text: 'Masuk', style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onTap;

  const _RoleCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.indigo : AppColors.linenDark, width: 1.4),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.charcoalSoft)),
        ]),
      ),
    );
  }
}
