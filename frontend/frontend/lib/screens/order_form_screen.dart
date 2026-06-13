import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tailor.dart';
import '../providers/orders_provider.dart';
import '../services/api_service.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _photos = [];
  String _category = 'Ubah Ukuran';
  String _deliveryMode = 'Antar ke toko';
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  String? _selectedTailorId;
  String? _error;
  bool _isSubmitting = false;
  bool _isEstimating = false;
  String? _estimateError;
  double? _estimateMin;
  double? _estimateMax;
  double? _estimateConfidence;
  String? _mlEstimationId;

  @override
  void initState() {
    super.initState();
    _refreshEstimate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedTailorId == null) {
      final routeArg = ModalRoute.of(context)?.settings.arguments;
      if (routeArg is Tailor && routeArg.id.isNotEmpty) {
        _selectedTailorId = routeArg.id;
      }
    }
  }

  String? get _resolvedTailorId {
    if (_selectedTailorId != null && _selectedTailorId!.isNotEmpty) {
      return _selectedTailorId;
    }
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    if (routeArg is Tailor && routeArg.id.isNotEmpty) {
      return routeArg.id;
    }
    return null;
  }

  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil foto dari kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih foto dari galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      await _pickPhotos(source: source);
    }
  }

  Future<void> _pickPhotos({required ImageSource source}) async {
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          if (_photos.length < 5) {
            _photos.add({'name': file.name, 'bytes': bytes});
          }
        });
      }
    } else {
      final picked = await picker.pickMultiImage(imageQuality: 70);
      if (picked.isNotEmpty) {
        for (final file in picked.take(5 - _photos.length)) {
          final bytes = await file.readAsBytes();
          setState(() {
            _photos.add({'name': file.name, 'bytes': bytes});
          });
        }
      }
    }
    await _refreshEstimate();
  }

  Future<void> _refreshEstimate() async {
    if (_photos.isEmpty) {
      setState(() {
        _estimateMin = null;
        _estimateMax = null;
        _estimateConfidence = null;
        _estimateError = null;
      });
      return;
    }

    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      final photos = _photos.map((photo) {
        final bytes = photo['bytes'] as Uint8List;
        final name = photo['name'] as String;
        return 'data:image/${name.split('.').last};base64,${base64Encode(bytes)}';
      }).toList();

      final estimate = await ApiService.estimatePrice(
        category: _category,
        description: _descriptionController.text.trim(),
        photos: photos,
      );

      if (!mounted) return;
      setState(() {
        final minPriceValue = estimate['min_price'];
        final maxPriceValue = estimate['max_price'];
        final confidenceValue = estimate['confidence'];
        final estimationId = estimate['id'];

        _estimateMin = minPriceValue is num
            ? minPriceValue.toDouble()
            : double.tryParse('$minPriceValue'.replaceAll(',', '').trim()) ?? 0.0;
        _estimateMax = maxPriceValue is num
            ? maxPriceValue.toDouble()
            : double.tryParse('$maxPriceValue'.replaceAll(',', '').trim()) ?? 0.0;
        _estimateConfidence = confidenceValue is num
            ? confidenceValue.toDouble()
            : double.tryParse('$confidenceValue'.replaceAll(',', '').trim()) ?? 0.0;
        _mlEstimationId = estimationId?.toString();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _estimateError = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isEstimating = false);
    }
  }

  Future<void> _submit() async {
    final tailorId = _resolvedTailorId;
    if (tailorId == null || tailorId.isEmpty) {
      setState(() => _error = 'Silakan pilih penjahit terlebih dahulu');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih penjahit terlebih dahulu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
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
        tailorId: tailorId,
        category: _category,
        description: _descriptionController.text.trim(),
        deadline: _deadline.toIso8601String(),
        deliveryMode: _deliveryMode,
        photos: photos,
        mlEstimationId: _mlEstimationId,
      );

      if (!mounted) return;

      // Tambahkan order baru ke provider agar langsung muncul di list
      ref.read(ordersProvider.notifier).addOrder(order);

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat!'),
          backgroundColor: Color(0xFF239B56),
          duration: Duration(seconds: 2),
        ),
      );

      // Langsung ke halaman Pesanan Saya
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/orders',
        (route) => route.settings.name == '/',
      );
    } catch (error) {
      setState(() => _error = error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailor = ModalRoute.of(context)?.settings.arguments as Tailor?;
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
              'Penjahit: ${tailor?.shopName ?? 'Belum dipilih'}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            if (_resolvedTailorId == null) ...[
              const SizedBox(height: 6),
              const Text(
                'Silakan pilih penjahit terlebih dahulu',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
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
                shadowColor: Colors.green.withValues(alpha: 0.18),
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
                        onTap: _showPhotoOptions,
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
                                  'Ambil foto atau pilih dari galeri (maks 5)',
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
                                            onTap: () => setState(() => _photos.remove(photo)),
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
                initialValue: _category,
                decoration: const InputDecoration(border: InputBorder.none),
                items: const [
                  'Ubah Ukuran',
                  'Ganti Ritsleting',
                  'Tambal',
                  'Sulam',
                  'Lainnya',
                ].map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ),
                ).toList(),
                onChanged: (value) {
                  setState(() => _category = value ?? _category);
                  _refreshEstimate();
                },
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
                onChanged: (_) => _refreshEstimate(),
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
                          color: Colors.green.shade200.withValues(alpha: 0.25),
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
                      children: [
                        const Text(
                          '✨ Estimasi Harga ML',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isEstimating)
                          const Text('Menghitung estimasi...', style: TextStyle(color: Colors.black54))
                        else if (_estimateError != null)
                          Text('Estimasi gagal: $_estimateError', style: const TextStyle(color: Colors.red))
                        else if (_estimateMin != null && _estimateMax != null && _estimateConfidence != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rp ${_estimateMin!.toStringAsFixed(0)} - Rp ${_estimateMax!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF239B56),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Kepercayaan: ${_estimateConfidence!.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.black54)),
                            ],
                          )
                        else
                          const Text(
                            'Unggah foto dan isi deskripsi untuk menghitung estimasi harga.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _photos.isNotEmpty ? _refreshEstimate : null,
                          child: const Text('Hitung Estimasi Harga'),
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
                initialValue: _deliveryMode,
                decoration: const InputDecoration(border: InputBorder.none),
                items: const ['Antar ke toko', 'Pickup oleh kurir mitra penjahit']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _deliveryMode = value ?? _deliveryMode),
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
                onPressed: _isSubmitting ? null : _submit,
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