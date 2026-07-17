import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';

/// Modul F-01: Reset password
class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;
  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await widget.authService.forgotPassword(_emailController.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Kata Sandi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            const SizedBox(height: 8),
            const Text('🔐', style: TextStyle(fontSize: 38), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Atur Ulang Kata Sandi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Masukkan email akunmu, kami akan kirimkan tautan untuk membuat kata sandi baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.charcoalSoft, height: 1.6),
            ),
            const SizedBox(height: 24),
            if (_sent) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sagePale,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(children: [
                  Icon(Icons.mark_email_read, color: AppColors.sage),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tautan reset kata sandi telah dikirim ke email kamu. Berlaku 30 menit.',
                      style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ]),
              ),
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Terdaftar', hintText: 'nama@email.com'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _send,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim Tautan Reset'),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('← Kembali ke halaman masuk'),
              ),
            ),
            const StitchDivider(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.sagePale, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.mail_outline, size: 18, color: AppColors.sage),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tautan berlaku 30 menit setelah dikirim ke email kamu.',
                      style: TextStyle(fontSize: 11.8, color: AppColors.sage, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
