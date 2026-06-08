import 'tailor.dart';
import 'order_timeline.dart';

class Order {
  final String id;
  final Tailor tailor;
  final String category;
  final String description;
  final List<String> photos;
  final DateTime deadline;
  final String deliveryMode;
  final double estimatedPriceMin;
  final double estimatedPriceMax;
  double finalPrice;
  String status;
  final DateTime createdAt;
  final String customerName;
  final List<OrderTimeline> timelines;

  Order({
    required this.id,
    required this.tailor,
    required this.category,
    required this.description,
    required this.photos,
    required this.deadline,
    required this.deliveryMode,
    required this.estimatedPriceMin,
    required this.estimatedPriceMax,
    required this.finalPrice,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.timelines,
  });

  double get estimatedPrice => (estimatedPriceMin + estimatedPriceMax) / 2;

  String get estimatedPriceLabel =>
      'Rp ${estimatedPriceMin.toStringAsFixed(0)} - Rp ${estimatedPriceMax.toStringAsFixed(0)}';

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

  factory Order.fromJson(Map<String, dynamic> json) {
    final tailorJson = json['tailor'] as Map<String, dynamic>? ?? {};
    return Order(
      id: json['id']?.toString() ?? '',
      tailor: Tailor.fromJson(tailorJson),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((item) {
                if (item is String) return item;
                if (item is Map<String, dynamic>) {
                  return item['path']?.toString() ?? '';
                }
                if (item is Map) {
                  return item['path']?.toString() ?? '';
                }
                return item.toString();
              })
              .where((path) => path.isNotEmpty)
              .toList() ?? [],
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ?? DateTime.now(),
      deliveryMode: json['delivery_mode'] ?? json['deliveryMode'] ?? '',
      estimatedPriceMin: (json['estimated_price_min'] is num)
          ? (json['estimated_price_min'] as num).toDouble()
          : double.tryParse('${json['estimated_price_min']}') ?? 0.0,
      estimatedPriceMax: (json['estimated_price_max'] is num)
          ? (json['estimated_price_max'] as num).toDouble()
          : double.tryParse('${json['estimated_price_max']}') ?? 0.0,
      finalPrice: (json['final_price'] is num) ? (json['final_price'] as num).toDouble() : double.tryParse('${json['final_price']}') ?? 0.0,
      status: json['status'] ?? 'waiting_confirmation',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      customerName: json['customer_name'] ?? json['customer']?.toString() ?? '',
      timelines: (json['timelines'] as List<dynamic>?)
              ?.map((item) => OrderTimeline.fromJson(item as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}
