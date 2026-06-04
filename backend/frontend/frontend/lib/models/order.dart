import 'tailor.dart';

class Order {
  final String id;
  final Tailor tailor;
  final String category;
  final String description;
  final List<String> photos;
  final DateTime deadline;
  final String deliveryMode;
  final double estimatedPrice;
  double finalPrice;
  String status;
  final DateTime createdAt;
  final String customerName;

  Order({
    required this.id,
    required this.tailor,
    required this.category,
    required this.description,
    required this.photos,
    required this.deadline,
    required this.deliveryMode,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.status,
    required this.createdAt,
    required this.customerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final tailorJson = json['tailor'] as Map<String, dynamic>? ?? {};
    return Order(
      id: json['id']?.toString() ?? '',
      tailor: Tailor.fromJson(tailorJson),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ?? DateTime.now(),
      deliveryMode: json['delivery_mode'] ?? json['deliveryMode'] ?? '',
      estimatedPrice: (json['estimated_price'] is num) ? (json['estimated_price'] as num).toDouble() : double.tryParse('${json['estimated_price']}') ?? 0.0,
      finalPrice: (json['final_price'] is num) ? (json['final_price'] as num).toDouble() : double.tryParse('${json['final_price']}') ?? 0.0,
      status: json['status'] ?? 'Menunggu Konfirmasi',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      customerName: json['customer_name'] ?? json['customer']?.toString() ?? '',
    );
  }
}
