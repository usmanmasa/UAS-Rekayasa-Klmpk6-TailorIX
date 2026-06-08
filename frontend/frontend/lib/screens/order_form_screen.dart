import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _photos = [];
  String _category = 'Ubah Ukuran';
  String _deliveryMode = 'Antar ke toko';
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  String? _error;
  bool _isSubmitting = false;

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      final photoData = <Map<String, dynamic>>[];
      for (final file in picked.take(5)) {
        final bytes = await file.readAsBytes();
        photoData.add({'name': file.name, 'bytes': bytes});
      }
      setState(() {
        _photos.clear();
        _photos.addAll(photoData);
      });
    }
  }

  Future<void> _submit(Tailor tailor) async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Deskripsi dibutuhkan untuk membuat pesanan.');
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _error = 'Mohon unggah minimal 1 foto pakaian.');
      return;
    }
    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      final photos = _photos.map((photo) {
        final bytes = photo['bytes'] as Uint8List;
        final name = photo['name'] as String;
        return 'data:image/${name.split('.').last};base64,${base64Encode(bytes)}';
      }).toList();

      final order = await ApiService.createOrder(
        tailorId: tailor.id,
        category: _category,
        description: _descriptionController.text.trim(),
        deadline: _deadline.toIso8601String(),
        deliveryMode: _deliveryMode,
        photos: photos,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/order-detail',
        arguments: order,
      );
    } catch (error) {
      setState(() => _error = error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailor = ModalRoute.of(context)!.settings.arguments as Tailor;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FEFA),
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pesanan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Penjahit: ${tailor.shopName}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload foto pakaian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickPhotos,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF239B56),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Upload foto pakaian (maks 5)',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _photos.isEmpty
                            ? const SizedBox.shrink()
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _photos.map((photo) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      children: [
                                        Image.memory(
                                          photo['bytes'] as Uint8List,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _photos.remove(photo),
                                            ),
                                            child: const CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.black54,
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFormCard(
              title: 'Kategori Jasa',
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(border: InputBorder.none),
                items:
                    const [
                          'Ubah Ukuran',
                          'Ganti Ritsleting',
                          'Tambal',
                          'Sulam',
                          'Lainnya',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
            ),
            const SizedBox(height: 14),
            _buildFormCard(
              title: 'Deskripsi Kebutuhan',
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Ceritakan kebutuhan permak...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: Color(0xFF239B56),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '✨ Estimasi Harga ML',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rp 45.000 - Rp 80.000',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF239B56),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kepercayaan: 87%',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildFormCard(
              title: 'Deadline',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pilih tanggal deadline'),
                subtitle: Text(
                  '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                ),
                trailing: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF239B56),
                ),
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
            ),
            const SizedBox(height: 14),
            _buildFormCard(
              title: 'Mode Pengiriman',
              child: DropdownButtonFormField<String>(
                value: _deliveryMode,
                decoration: const InputDecoration(border: InputBorder.none),
                items:
                    const ['Antar ke toko', 'Pickup oleh kurir mitra penjahit']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => _deliveryMode = value ?? _deliveryMode),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF239B56),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isSubmitting ? null : () => _submit(tailor),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        'Kirim Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      shadowColor: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
