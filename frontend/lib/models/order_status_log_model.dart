class OrderStatusLog {
  final int id;
  final int orderId;
  final String status;
  final String? note;
  final String? photoPath;
  final DateTime? createdAt;

  OrderStatusLog({
    required this.id,
    required this.orderId,
    required this.status,
    this.note,
    this.photoPath,
    this.createdAt,
  });

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    try {
      if (json['created_at'] != null) {
        created = DateTime.parse(json['created_at']);
      }
    } catch (_) {
      created = null;
    }

    return OrderStatusLog(
      id: json['id'],
      orderId: json['order_id'],
      status: json['status'] ?? '',
      note: json['note'] as String?,
      photoPath: json['photo_path'] as String?,
      createdAt: created,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Menunggu konfirmasi';
      case 'menunggu_pembayaran':
        return 'Menunggu pembayaran';
      case 'diproses':
        return 'Sedang diproses';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
