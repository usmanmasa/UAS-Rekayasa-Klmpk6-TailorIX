import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/order_status_log_model.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/stitch_divider.dart';
import '../chat/chat_screen.dart';

/// Langkah 13-22: Menampilkan status pesanan secara real-time (menunggu
/// konfirmasi -> menunggu pembayaran -> diproses -> selesai), memicu
/// pembayaran Midtrans, dan memberi ulasan setelah selesai.
class OrderTrackingScreen extends StatefulWidget {
  final OrderService orderService;
  final ApiClient apiClient;
  final int orderId;
  final int currentUserId;

  const OrderTrackingScreen({
    super.key,
    required this.orderService,
    required this.apiClient,
    required this.orderId,
    required this.currentUserId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with WidgetsBindingObserver {
  Order? _order;
  bool _loading = true;
  bool _submittingReview = false;
  String? _errorMessage;
  Timer? _paymentPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app returns to foreground (e.g., user returns from external
    // Midtrans page), refresh order status so UI updates.
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final order = await widget.orderService.getOrderDetail(widget.orderId);
      setState(() => _order = order);
    } catch (e) {
      debugPrint('Failed to refresh order ${widget.orderId}: $e');
      setState(() {
        _errorMessage = 'Gagal memuat detail pesanan. Coba lagi nanti.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay(String type, double amount) async {
    // Langkah 15-16: minta snap token, lalu buka halaman pembayaran Snap Midtrans.
    try {
      final snapToken = await widget.orderService.requestPayment(
        orderId: widget.orderId,
        paymentType: type,
        amount: amount,
      );

      if (snapToken.isEmpty) {
        debugPrint(
            'requestPayment returned empty snap token for order ${widget.orderId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Gagal mendapatkan token pembayaran.')));
        }
        return;
      }

      // URL resmi Snap (vtweb) berdasarkan snap_token; bisa dibuka di browser
      // eksternal maupun di-load dalam WebView khusus jika ingin tampilan in-app.
      const host = ApiClient.isMidtransProduction
          ? 'app.midtrans.com'
          : 'app.sandbox.midtrans.com';
      final snapUrl = Uri.parse('https://$host/snap/v2/vtweb/$snapToken');

      final opened =
          await launchUrl(snapUrl, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('Unable to open snapUrl: $snapUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tidak bisa membuka halaman pembayaran.')),
          );
        }
        return;
      }

      // Setelah pelanggan menyelesaikan pembayaran di halaman Snap, Midtrans
      // mengirim webhook ke backend (langkah 17) yang mengubah status pesanan.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Selesaikan pembayaran di halaman yang terbuka, lalu kembali ke aplikasi.')),
        );
      }

      // Start polling order status for up to 2 minutes so the app detects
      // payment completion without requiring an externally-accessible webhook.
      _paymentPollTimer?.cancel();
      final pollInterval = const Duration(seconds: 5);
      final pollTimeout = DateTime.now().add(const Duration(minutes: 2));
      _paymentPollTimer = Timer.periodic(pollInterval, (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        await _refresh();
        if (_order != null && _order!.status != 'menunggu_pembayaran') {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Pembayaran terdeteksi. Status pesanan diperbarui.')));
          }
          return;
        }
        if (DateTime.now().isAfter(pollTimeout)) {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Belum menerima notifikasi pembayaran. Tekan refresh nanti.')));
          }
        }
      });
    } catch (e, st) {
      debugPrint('Error starting payment for order ${widget.orderId}: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terjadi kesalahan saat memulai pembayaran: $e')));
      }
    } finally {
      await _refresh();
    }
  }

  Future<void> _giveReview() async {
    int rating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beri ulasan & rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (ctx, setStateDialog) => Row(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(i < rating ? Icons.star : Icons.star_border),
                    onPressed: () => setStateDialog(() => rating = i + 1),
                  ),
                ),
              ),
            ),
            TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Komentar')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: _submittingReview
                ? null
                : () async {
                    setState(() => _submittingReview = true);
                    try {
                      await widget.orderService.submitReview(
                        orderId: widget.orderId,
                        rating: rating,
                        comment: commentController.text,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _refresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ulasan berhasil dikirim.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengirim ulasan: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _submittingReview = false);
                    }
                  },
            child: _submittingReview
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _onCancelPressed() async {
    final message = _order!.canCancelDirectly
        ? 'Apakah Anda yakin ingin membatalkan pesanan ini?'
        : 'Pesanan sudah dikonfirmasi. Ajukan permintaan pembatalan dan tunggu persetujuan penjahit.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembatalan'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (_order!.canCancelDirectly) {
        await widget.orderService.cancelOrder(widget.orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan dibatalkan.')));
        }
      } else {
        await widget.orderService.requestOrderCancellation(widget.orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permintaan pembatalan dikirim.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memproses pembatalan: $e')));
      }
    } finally {
      await _refresh();
    }
  }

  /// Urutan tahap pesanan sesuai sequence diagram backend, dipakai untuk
  /// menggambar linimasa jelujur (lihat juga `AppColors.statusStyles`).
  static const _timelineOrder = [
    'menunggu_konfirmasi',
    'menunggu_pembayaran',
    'diproses',
    'selesai',
  ];

  int _stepIndexFor(String status) {
    if (status == 'ditolak' || status == 'dibatalkan') return -1;
    return _timelineOrder.indexOf(status);
  }

  Widget _buildTimeline(Order order) {
    final currentIndex = _stepIndexFor(order.status);
    const labels = [
      'Menunggu konfirmasi penjahit',
      'Diterima, menunggu pembayaran',
      'Sedang dikerjakan',
      'Selesai & siap diambil',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length, (i) {
        final done = currentIndex > i;
        final now = currentIndex == i;
        final color = done || now ? AppColors.gold : AppColors.linenDark;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || now ? AppColors.gold : Colors.white,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : (now
                          ? const Icon(Icons.circle,
                              size: 8, color: Colors.white)
                          : null),
                ),
                if (i != labels.length - 1)
                  const StitchTimelineConnector(height: 30),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color:
                      done || now ? AppColors.charcoal : AppColors.charcoalSoft,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusLogItem(OrderStatusLog log) {
    final createdAt = log.createdAt?.toLocal();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.linenDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (createdAt != null)
            Text(
              '${_formatDate(createdAt)} ${_formatTime(createdAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft),
            ),
          const SizedBox(height: 6),
          Text(log.statusLabel,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.indigo)),
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.note!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.charcoal)),
          ],
          if (log.photoPath != null && log.photoPath!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                ApiClient.storageProxyUrl(log.photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.linen,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: AppColors.charcoalSoft),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 52, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kartu ringkasan pesanan.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.linen,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.content_cut,
                                color: AppColors.indigo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_order!.categoryName ?? 'Pesanan Permak',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5)),
                                const SizedBox(height: 3),
                                Text(_order!.orderCode,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.charcoalSoft,
                                        fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: _order!.status),
                              if (_order!.isCancellationPending) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldPale,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'Menunggu persetujuan',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldDeep),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const StitchDivider(),

                  Text('Status Pesanan',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 14),
                  _buildTimeline(_order!),

                  const SizedBox(height: 12),

                  if (_order!.estimatedPrice != null ||
                      _order!.finalPrice != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL TAGIHAN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.charcoalSoft,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${(_order!.finalPrice ?? _order!.estimatedPrice)?.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.indigo),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_order!.statusLogs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('Riwayat Progres',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 10),
                    Column(
                      children: _order!.statusLogs
                          .map((log) => _buildStatusLogItem(log))
                          .toList(),
                    ),
                  ],
                  if (_order!.cancellationStatus == 'pending') ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.goldPale,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Text(
                        'Permintaan pembatalan sedang menunggu persetujuan penjahit.',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDeep),
                      ),
                    ),
                  ],
                  if (_order!.canCancelDirectly ||
                      _order!.canRequestCancellation) ...[
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _onCancelPressed,
                      child: const Text('Batalkan Pesanan'),
                    ),
                  ],

                  if (_order!.status == 'menunggu_pembayaran') ...[
                    const SizedBox(height: 18),
                    const Text('Pilih metode pembayaran',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _pay('dp', (_order!.estimatedPrice ?? 0) * 0.5),
                            child: const Text('Bayar DP'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                _pay('pelunasan', _order!.estimatedPrice ?? 0),
                            child: const Text('Bayar Lunas'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_order!.status == 'selesai') ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.goldPale,
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order!.hasReview
                                ? 'Terima kasih! Ulasan telah terkirim untuk penjahit.'
                                : 'Penjahit sudah menyelesaikan jahitan. Beri rating dan ulasan untuk membantu penjahit.',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.goldDeep),
                          ),
                          if (!_order!.hasReview) ...[
                            const SizedBox(height: 10),
                            FilledButton(
                                onPressed: _submittingReview ? null : _giveReview,
                                child: const Text('Beri Ulasan & Rating')),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (_order!.status == 'ditolak')
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.redPale,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _order!.rejectionReason?.isNotEmpty == true
                                  ? 'Pesanan ditolak: ${_order!.rejectionReason}'
                                  : 'Pesanan ditolak oleh penjahit.',
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentPollTimer?.cancel();
    super.dispose();
  }
}
