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
  final double locationLat;
  final double locationLng;
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
    required this.locationLat,
    required this.locationLng,
    required this.portfolio,
    required this.description,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    final kategori = json['kategori'];
    return Tailor(
      id: json['id']?.toString() ?? '',
      name: json['nama'] ?? json['name'] ?? json['shop_name'] ?? '',
      shopName: json['nama'] ?? json['shop_name'] ?? json['name'] ?? '',
      city: json['alamat'] ?? json['city'] ?? json['location'] ?? '',
      specializations: kategori is String
          ? [kategori]
          : (kategori as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      isAvailable: status == 'buka' || json['is_available'] == true || json['available'] == true,
      reviewsCount: (json['reviews_count'] is int)
          ? json['reviews_count'] as int
          : int.tryParse('${json['reviews_count']}') ?? 0,
      distanceKm: (json['distance_km'] is num)
          ? (json['distance_km'] as num).toDouble()
          : double.tryParse('${json['distance_km']}') ?? 0.0,
      locationLat: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : (json['location_lat'] is num)
              ? (json['location_lat'] as num).toDouble()
              : double.tryParse('${json['latitude']}') ?? 0.0,
      locationLng: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : (json['location_lng'] is num)
              ? (json['location_lng'] as num).toDouble()
              : double.tryParse('${json['longitude']}') ?? 0.0,
      portfolio: (json['portfolio'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
      description: json['description'] ?? kategori?.toString() ?? '',
    );
  }
}
