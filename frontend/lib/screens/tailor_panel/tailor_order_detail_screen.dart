import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/order_model.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/order_service.dart';
import '../../services/tailor_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_screen.dart';

/// Detail satu pesanan dari sudut pandang penjahit.
/// - Langkah 13-14: terima/tolak pesanan yang masih `menunggu_konfirmasi`,
///   dengan penjahit menetapkan harga final saat menerima.
/// - Langkah 19-20: ubah status pengerjaan (`diproses` -> `selesai`), boleh
///   melampirkan foto progres pengerjaan.
/// - Chat dengan pelanggan terkait pesanan ini.
class TailorOrderDetailScreen extends StatefulWidget {
  final TailorService tailorService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int orderId;
  final int currentUserId;

  const TailorOrderDetailScreen({
    super.key,
    required this.tailorService,
    required this.orderService,
    required this.apiClient,
    required this.orderId,
    required this.currentUserId,
  });

  @override
  State<TailorOrderDetailScreen> createState() =>
      _TailorOrderDetailScreenState();
}

class _TailorOrderDetailScreenState extends State<TailorOrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  bool _submitting = false;

  // Langkah 13-14: harga final yang penjahit tetapkan saat menerima pesanan.
  final _priceController = TextEditingController();

  // Langkah 19-20: foto progres pengerjaan (opsional) yang dilampirkan saat
  // status diperbarui.
  XFile? _progressPhotoFile;
  Uint8List? _progressPhotoBytes;
  String? _progressPhotoPath;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final order = await widget.orderService.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        if (_priceController.text.isEmpty) {
          _priceController.text = (order.estimatedPrice ?? 0) > 0
              ? order.estimatedPrice!.toStringAsFixed(0)
              : '';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProgressPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _progressPhotoFile = picked;
      _progressPhotoBytes = bytes;
      _uploadingPhoto = true;
      _progressPhotoPath = null;
    });

    try {
      final path = await UploadService(widget.apiClient).uploadImage(picked);
      setState(() => _progressPhotoPath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
      }
      setState(() => _progressPhotoFile = null);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _respond(bool accept) async {
    String? reason;
    double? finalPrice;

    if (accept) {
      finalPrice = double.tryParse(_priceController.text.trim());
      if (finalPrice == null || finalPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Isi harga final yang valid sebelum menerima pesanan.')),
        );
        return;
      }
    } else {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tolak pesanan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Alasan penolakan'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tolak pesanan')),
          ],
        ),
      );
      if (confirmed != true) return;
      reason = controller.text;
    }

    setState(() => _submitting = true);
    try {
      await widget.tailorService.respondToOrder(
        orderId: widget.orderId,
        accept: accept,
        rejectionReason: reason,
        finalPrice: finalPrice,
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal merespons pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _updateProgress(String status) async {
    setState(() => _submitting = true);
    try {
      await widget.tailorService.updateProgress(
        orderId: widget.orderId,
        status: status,
        photoPath: _progressPhotoPath,
      );
      setState(() {
        _progressPhotoFile = null;
        _progressPhotoPath = null;
      });
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        title: Text(
            order != null ? 'Pesanan ${order.orderCode}' : 'Detail Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: order == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatService: ChatService(widget.apiClient),
                          orderId: widget.orderId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading || order == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.linen,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.indigo),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.pelangganName ?? '-',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              if (order.pelangganPhone != null)
                                Text(order.pelangganPhone!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.charcoalSoft)),
                            ]),
                      ),
                      StatusBadge(status: order.status),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('DETAIL PERMINTAAN',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.gold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                              label: 'Kategori',
                              value: order.categoryName ?? '-'),
                          _InfoRow(
                              label: 'Tenggat',
                              value:
                                  '${order.deadline.day}-${order.deadline.month}-${order.deadline.year}'),
                          _InfoRow(
                              label: 'Estimasi Harga',
                              value: order.estimatedPrice != null
                                  ? 'Rp${order.estimatedPrice!.toStringAsFixed(0)}'
                                  : '-'),
                          if (order.finalPrice != null)
                            _InfoRow(
                                label: 'Harga Final',
                                value:
                                    'Rp${order.finalPrice!.toStringAsFixed(0)}'),
                          const Divider(height: 20),
                          Text(
                              order.description ??
                                  'Tidak ada deskripsi tambahan.',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.charcoalSoft,
                                  height: 1.6)),
                        ]),
                  ),

                  if (order.status == 'ditolak' &&
                      order.rejectionReason != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                          color: AppColors.redPale,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Alasan penolakan: ${order.rejectionReason}',
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Langkah 13-14: aksi terima/tolak hanya muncul saat menunggu konfirmasi
                  if (order.status == 'menunggu_konfirmasi') ...[
                    Text('TETAPKAN HARGA & TERIMA',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.gold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Harga Final (Rp)',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(color: AppColors.red)),
                            onPressed:
                                _submitting ? null : () => _respond(false),
                            child: const Text('Tolak Pesanan'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _submitting ? null : () => _respond(true),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Terima & Kirim Harga'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Langkah 19-20: penjahit mulai mengerjakan / menandai selesai
                  if (order.status == 'menunggu_pembayaran')
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE4E8F2),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Text(
                          'Menunggu pelanggan menyelesaikan pembayaran.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.indigo,
                              fontWeight: FontWeight.w600)),
                    ),

                  if (order.status == 'diproses') ...[
                    Text('UPDATE PROGRES PENGERJAAN',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.gold)),
                    const SizedBox(height: 8),
                    if (_progressPhotoFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_progressPhotoBytes!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingPhoto || _submitting
                                ? null
                                : _pickProgressPhoto,
                            icon: _uploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(
                                    _progressPhotoPath != null
                                        ? Icons.check_circle
                                        : Icons.camera_alt_outlined,
                                    size: 17,
                                    color: _progressPhotoPath != null
                                        ? AppColors.sage
                                        : null),
                            label: Text(
                              _uploadingPhoto
                                  ? 'Mengunggah…'
                                  : _progressPhotoPath != null
                                      ? 'Foto Terlampir'
                                      : 'Tambah Foto Progres',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.indigoDeep),
                            onPressed: _submitting || _uploadingPhoto
                                ? null
                                : () => _updateProgress('selesai'),
                            child: const Text('Tandai Selesai'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.charcoalSoft)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
