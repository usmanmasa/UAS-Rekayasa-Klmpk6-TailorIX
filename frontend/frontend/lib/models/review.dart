class Review {
  final String id;
  final String orderId;
  final String authorName;
  final double rating;
  final String comment;
  final List<String> photos;
  final String? reply;

  Review({
    required this.id,
    required this.orderId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.photos,
    this.reply,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? json['authorName']?.toString() ?? '',
      rating: (json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? '0') ?? 0),
      comment: json['comment']?.toString() ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      reply: json['reply']?.toString(),
    );
  }
}
