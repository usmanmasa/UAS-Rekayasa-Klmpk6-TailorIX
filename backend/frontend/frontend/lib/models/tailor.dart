class Tailor {
  final String id;
  final String name;
  final String shopName;
  final String city;
  final List<String> specializations;
  final double rating;
  final bool isAvailable;
  final int reviewsCount;
  final double distanceKm;
  final List<String> portfolio;
  final String description;

  Tailor({
    required this.id,
    required this.name,
    required this.shopName,
    required this.city,
    required this.specializations,
    required this.rating,
    required this.isAvailable,
    required this.reviewsCount,
    required this.distanceKm,
    required this.portfolio,
    required this.description,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) {
    return Tailor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['tailor_name'] ?? '',
      shopName: json['shop_name'] ?? json['name'] ?? '',
      city: json['city'] ?? json['location'] ?? '',
      specializations: (json['specializations'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      isAvailable: json['is_available'] == true || json['available'] == true,
      reviewsCount: (json['reviews_count'] is int) ? json['reviews_count'] as int : int.tryParse('${json['reviews_count']}') ?? 0,
      distanceKm: (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : 0.0,
      portfolio: (json['portfolio'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      description: json['description'] ?? '',
    );
  }
}
