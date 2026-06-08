import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _message = null;
      _isSaving = true;
    });

    String? errorMessage;
    try {
      await ApiService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errorMessage != null) {
      setState(() => _message = errorMessage);
      return;
    }

    setState(() => _message = 'Profil berhasil diperbarui.');
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Akun Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.badge),
                title: Text(user?.role.toUpperCase() ?? '-'),
                subtitle: const Text('Peran'),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(user?.email ?? '-'),
                subtitle: const Text('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.home)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (_message != null) ...[
                Text(_message!, style: TextStyle(color: _message == 'Profil berhasil diperbarui.' ? Colors.green : Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Profil'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ApiService.logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
