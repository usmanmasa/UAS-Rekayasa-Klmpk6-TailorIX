import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Pengaturan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 16),
            Text('Halaman pengaturan belum tersedia sepenuhnya, tetapi menu ini dapat dikembangkan lebih lanjut.'),
          ],
        ),
      ),
    );
  }
}
