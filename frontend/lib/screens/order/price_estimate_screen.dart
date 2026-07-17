import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pickup_slot_model.dart';
import '../../models/price_estimate_model.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stitch_divider.dart';
import 'order_tracking_screen.dart';

/// Langkah 10-12: Sistem menampilkan estimasi harga, pelanggan menyetujui
/// dan mengirimkan pesanan ke penjahit.
class PriceEstimateScreen extends StatefulWidget {
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final int tailorId;
  final int categoryId;
  final String? description;
  final String? photoPath;
  final DateTime deadline;
  final PickupSlotOption? selectedPickupSlot;
  final PriceEstimate estimateData;
  final double? customerLatitude;
  final double? customerLongitude;
  final String? customerAddress;

  const PriceEstimateScreen({
    super.key,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    required this.tailorId,
    required this.categoryId,
    this.description,
    this.photoPath,
    required this.deadline,
    this.selectedPickupSlot,
    required this.estimateData,
    this.customerLatitude,
    this.customerLongitude,
    this.customerAddress,
  });

  @override
  State<PriceEstimateScreen> createState() => _PriceEstimateScreenState();
}

class _PriceEstimateScreenState extends State<PriceEstimateScreen> {
  bool _loading = false;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _confirmOrder() async {
    setState(() => _loading = true);
    try {
      final order = await widget.orderService.createOrder(
        tailorId: widget.tailorId,
        categoryId: widget.categoryId,
        description: widget.description,
        photoPath: widget.photoPath,
        deadline: widget.deadline,
        estimatedPrice: widget.estimateData.totalEstimasi,
        pickupTanggal: widget.selectedPickupSlot != null
            ? DateTime.parse(widget.selectedPickupSlot!.tanggal)
            : null,
        pickupJamMulai: widget.selectedPickupSlot?.jamMulai,
        pickupJamSelesai: widget.selectedPickupSlot?.jamSelesai,
        customerLatitude: widget.customerLatitude,
        customerLongitude: widget.customerLongitude,
        customerAddress: widget.customerAddress,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderService: widget.orderService,
            apiClient: widget.apiClient,
            currentUserId: widget.currentUserId,
            orderId: order.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estimasi Harga')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _summaryRow('Kategori', 'Kategori #${widget.categoryId}'),
                _summaryRow('Tenggat', '${widget.deadline.toLocal()}'.split(' ').first),
                _summaryRow('Foto Dilampirkan', widget.photoPath != null ? '1 foto' : 'Tidak ada'),
              ]),
            ),
            const SizedBox(height: 12),
            const StitchDivider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.indigo, AppColors.indigoLight]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ESTIMASI BIAYA',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.goldLight)),
                const SizedBox(height: 6),
                _buildDetailRow('Subtotal Jasa Jahit', _currency.format(widget.estimateData.subtotalJasa)),
                const SizedBox(height: 8),
                _buildDetailRow('Biaya Pickup/Antar', _currency.format(widget.estimateData.biayaPickup)),
                if (widget.estimateData.pickupDistanceKm != null) ...[
                  const SizedBox(height: 6),
                  _buildDetailRow('Jarak Pickup', '${widget.estimateData.pickupDistanceKm!.toStringAsFixed(2)} km'),
                  const SizedBox(height: 6),
                  _buildDetailRow('Tarif Dasar', _currency.format(widget.estimateData.pickupBaseFare ?? 0)),
                  const SizedBox(height: 6),
                  _buildDetailRow('Biaya Jarak Tambahan', _currency.format(widget.estimateData.pickupExtraFee ?? 0)),
                ],
                const SizedBox(height: 8),
                _buildDetailRow('Biaya Layanan', _currency.format(widget.estimateData.biayaLayanan)),
                const Divider(color: Colors.white24, height: 32, thickness: 1),
                Text('Total Estimasi', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(_currency.format(widget.estimateData.totalEstimasi),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 12),
                const Text('Harga sudah termasuk ongkir dan pickup. Harga final ditentukan penjahit setelah memeriksa pakaian langsung.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.indigoDeep),
              onPressed: _loading ? null : _confirmOrder,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim Pesanan ke Penjahit'),
            ),
            const SizedBox(height: 12),
            if (widget.selectedPickupSlot != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.linenDark, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup terjadwal',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoalSoft)),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.selectedPickupSlot!.tanggal} • ${widget.selectedPickupSlot!.label}',
                      style: const TextStyle(
                          fontSize: 13.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigoDeep),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Pesanan akan menunggu konfirmasi dari penjahit',
                  style: TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12.6, color: AppColors.charcoalSoft)),
        Text(value, style: const TextStyle(fontSize: 12.6, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12.6, color: Colors.white70))),
      Text(value, style: const TextStyle(fontSize: 12.6, fontWeight: FontWeight.w700, color: Colors.white)),
    ]);
  }
}
