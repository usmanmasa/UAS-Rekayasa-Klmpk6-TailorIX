import 'json_helpers.dart';
import 'order_status_log_model.dart';
import 'pickup_slot_model.dart';

class Order {
  final int id;
  final String orderCode;
  final int tailorId;
  final int categoryId;
  final String? description;
  final String? photoPath;
  final DateTime deadline;
  final DateTime? createdAt;
  final double? estimatedPrice;
  final double? finalPrice;
  final String status;
  final String cancellationStatus;
  final String? rejectionReason;
  final String? pelangganName;
  final String? pelangganPhone;
  final String? categoryName;
  final String? tailorName;
  final bool hasReview;
  final List<OrderStatusLog> statusLogs;
  final PickupSlotOption? pickupSlot;

  Order({
    required this.id,
    required this.orderCode,
    required this.tailorId,
    required this.categoryId,
    this.description,
    this.photoPath,
    required this.deadline,
    this.createdAt,
    this.estimatedPrice,
    this.finalPrice,
    required this.status,
    required this.cancellationStatus,
    this.rejectionReason,
    this.pelangganName,
    this.pelangganPhone,
    this.categoryName,
    this.tailorName,
    this.hasReview = false,
    this.statusLogs = const [],
    this.pickupSlot,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final pelanggan = json['pelanggan'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    final tailor = json['tailor'] as Map<String, dynamic>?;
    DateTime? created;
    try {
      if (json['created_at'] != null) {
        created = DateTime.parse(json['created_at']);
      }
    } catch (_) {
      created = null;
    }
    final review = json['review'] as Map<String, dynamic>?;
    return Order(
      id: json['id'],
      orderCode: json['order_code'] ?? '',
      tailorId: json['tailor_id'],
      categoryId: json['category_id'],
      description: json['description'],
      photoPath: json['photo_path'],
      deadline: DateTime.parse(json['deadline']),
      createdAt: created,
      estimatedPrice: parseDouble(json['estimated_price']),
      finalPrice: parseDouble(json['final_price']),
      status: json['status'] ?? 'menunggu_konfirmasi',
      cancellationStatus: json['cancellation_status'] ?? 'none',
      rejectionReason: json['rejection_reason'],
      pelangganName: pelanggan != null ? pelanggan['name'] as String? : null,
      pelangganPhone: pelanggan != null ? pelanggan['phone'] as String? : null,
      categoryName: category != null ? category['name'] as String? : null,
      tailorName: tailor != null ? tailor['shop_name'] as String? : null,
      hasReview: review != null,
      statusLogs: (json['status_logs'] as List?)
              ?.map((e) => OrderStatusLog.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      pickupSlot: json['pickup_slot'] != null
          ? PickupSlotOption.fromJson(json['pickup_slot'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Label status sesuai alur pada sequence diagram
  String get statusLabel {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Menunggu konfirmasi penjahit';
      case 'ditolak':
        return 'Pesanan ditolak';
      case 'menunggu_pembayaran':
        return 'Menunggu pembayaran';
      case 'diproses':
        return 'Sedang dikerjakan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get cancellationStatusLabel {
    switch (cancellationStatus) {
      case 'none':
        return '';
      case 'pending':
        return 'Menunggu persetujuan pembatalan';
      case 'approved':
        return 'Pembatalan disetujui';
      case 'rejected':
        return 'Permintaan pembatalan ditolak';
      default:
        return cancellationStatus;
    }
  }

  bool get isCancellationPending => cancellationStatus == 'pending';
  bool get canCancelDirectly =>
      status == 'menunggu_konfirmasi' && cancellationStatus == 'none';
  bool get canRequestCancellation =>
      (status == 'menunggu_pembayaran' || status == 'diproses') &&
      cancellationStatus == 'none';
  bool get canSubmitReview => status == 'selesai' && !hasReview;

  @override
  String toString() => 'Order(id: $id, status: $status, hasReview: $hasReview)';
}
