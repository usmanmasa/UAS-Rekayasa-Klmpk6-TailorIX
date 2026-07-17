class AppNotification {
  final int id;
  final int? orderId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    this.orderId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      orderId: json['order_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
