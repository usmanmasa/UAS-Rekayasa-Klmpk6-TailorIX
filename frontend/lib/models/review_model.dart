class TailorReview {
  final int id;
  final int rating;
  final String? comment;
  final String? pelangganName;

  TailorReview({
    required this.id,
    required this.rating,
    this.comment,
    this.pelangganName,
  });

  factory TailorReview.fromJson(Map<String, dynamic> json) {
    final pelanggan = json['pelanggan'] as Map<String, dynamic>?;
    return TailorReview(
      id: json['id'],
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      pelangganName: pelanggan != null ? pelanggan['name'] as String? : null,
    );
  }
}
