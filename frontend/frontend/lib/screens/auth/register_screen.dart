import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'customer';
  bool _termsAccepted = false;
  String? _error;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final shopName = _shopNameController.text.trim();
    final password = _passwordController.text.trim();
    if (!_termsAccepted) {
      setState(
        () => _error =
            'Silakan setuju Syarat & Ketentuan serta Kebijakan Privasi untuk melanjutkan.',
      );
      return;
    }
    setState(() => _error = null);
    try {
      await ApiService.register(
        name,
        email,
        phone,
        password,
        role: _role,
        address: address.isNotEmpty ? address : null,
        shopName: _role == 'tailor' ? shopName : null,
        termsAccepted: _termsAccepted,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/app');
    } catch (error) {
      setState(() => _error = error.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi TailoriX')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.home),
                ),
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Daftar sebagai',
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Pelanggan')),
                  DropdownMenuItem(value: 'tailor', child: Text('Penjahit')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value ?? 'customer';
                  });
                },
              ),
              if (_role == 'tailor') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko / Studio',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _termsAccepted,
                controlAffinity: ListTileControlAffinity.leading,
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Saya setuju dengan '),
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showLegalDialog(
                            context,
                            'Syarat & Ketentuan',
                            'Syarat & Ketentuan TailoriX...',
                          ),
                      ),
                      const TextSpan(text: ' dan '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showLegalDialog(
                            context,
                            'Kebijakan Privasi',
                            'Kebijakan Privasi TailoriX...',
                          ),
                      ),
                    ],
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(onPressed: _register, child: const Text('Daftar')),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
