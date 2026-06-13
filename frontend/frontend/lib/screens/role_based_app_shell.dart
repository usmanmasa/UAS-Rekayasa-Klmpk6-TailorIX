import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'admin_shell.dart';
import 'app_shell.dart';
import 'tailor_shell.dart';

class RoleBasedAppShell extends ConsumerWidget {
  const RoleBasedAppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Silakan login terlebih dahulu'),
          ),
        ),
      ),
      data: (user) {
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
      },
    );
  }
}
