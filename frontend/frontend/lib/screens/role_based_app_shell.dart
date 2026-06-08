import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_shell.dart';
import 'app_shell.dart';
import 'tailor_shell.dart';

class RoleBasedAppShell extends StatelessWidget {
  const RoleBasedAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Silakan login terlebih dahulu'),
          ),
        ),
      );
    }

    switch (user.role) {
      case 'admin':
        return const AdminShell();
      case 'tailor':
        return const TailorShell();
      default:
        return const AppShell();
    }
  }
}
