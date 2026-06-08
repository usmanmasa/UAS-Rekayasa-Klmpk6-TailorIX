class OrderTimeline {
  final int id;
  final String status;
  final String notes;
  final DateTime createdAt;

  OrderTimeline({
    required this.id,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get statusLabel {
    return {
      'waiting_confirmation': 'Menunggu Konfirmasi',
      'confirmed': 'Dikonfirmasi',
      'accepted': 'Diterima Penjahit',
      'process': 'Proses Permak',
      'ready_for_pickup': 'Siap Diambil',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    }[status] ?? status;
  }
}
