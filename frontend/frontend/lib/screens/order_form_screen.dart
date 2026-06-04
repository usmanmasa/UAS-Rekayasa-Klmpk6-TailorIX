import 'package:flutter/material.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _descriptionController = TextEditingController();
  String _category = 'Ubah Ukuran';
  String _deliveryMode = 'Antar ke toko';
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  String? _error;

  Future<void> _submit(Tailor tailor) async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Deskripsi dibutuhkan untuk membuat pesanan.');
      return;
    }
    setState(() {
      _error = null;
    });
    try {
      final order = await ApiService.createOrder(
        tailorId: tailor.id,
        category: _category,
        description: _descriptionController.text.trim(),
        deadline: _deadline.toIso8601String(),
        deliveryMode: _deliveryMode,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-detail', arguments: order);
    } catch (error) {
      setState(() => _error = error.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailor = ModalRoute.of(context)!.settings.arguments as Tailor;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penjahit: ${tailor.shopName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                'Ubah Ukuran',
                'Ganti Ritsleting',
                'Tambal',
                'Sulam',
                'Lainnya'
              ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _category = value ?? _category),
              decoration: const InputDecoration(labelText: 'Kategori Jasa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Deskripsi kebutuhan permak', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline pengerjaan'),
              subtitle: Text('${_deadline.day}/${_deadline.month}/${_deadline.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final nextDate = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (nextDate != null) setState(() => _deadline = nextDate);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _deliveryMode,
              items: const ['Antar ke toko', 'Pickup oleh kurir mitra penjahit']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _deliveryMode = value ?? _deliveryMode),
              decoration: const InputDecoration(labelText: 'Mode Pengiriman'),
            ),
            const SizedBox(height: 12),
            const Text('Foto pakaian diunggah saat ini hanya demo frontend; fitur upload akan terhubung pada backend nanti.'),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(onPressed: () => _submit(tailor), child: const Text('Kirim Pesanan')),
          ],
        ),
      ),
    );
  }
}
