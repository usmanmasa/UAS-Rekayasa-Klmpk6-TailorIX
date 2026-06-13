import 'dart:convert';

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
  final double estimatedPrice;

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
    this.estimatedPrice = 0.0,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    final kategori = json['kategori'];

    List<String> parsedSpecializations;
    if (kategori is List) {
      parsedSpecializations = kategori.map((item) => item.toString()).toList();
    } else if (kategori is String) {
      final trimmed = kategori.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            parsedSpecializations = decoded.map((item) => item.toString()).toList();
          } else {
            parsedSpecializations = [trimmed];
          }
        } catch (_) {
          parsedSpecializations = [trimmed];
        }
      } else {
        parsedSpecializations = [trimmed];
      }
    } else {
      parsedSpecializations = [];
    }

    return Tailor(
      id: json['id']?.toString() ?? '',
      name: json['nama'] ?? json['name'] ?? json['shop_name'] ?? '',
      shopName: json['nama'] ?? json['shop_name'] ?? json['name'] ?? '',
      city: json['alamat'] ?? json['city'] ?? json['location'] ?? '',
      specializations: parsedSpecializations,
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
      description: json['description'] ?? (parsedSpecializations.isNotEmpty ? parsedSpecializations.join(', ') : ''),
      estimatedPrice: (json['estimated_price'] is num)
          ? (json['estimated_price'] as num).toDouble()
          : (json['ml_price_min'] is num)
              ? (json['ml_price_min'] as num).toDouble()
              : (json['harga'] is num)
                  ? (json['harga'] as num).toDouble()
                  : double.tryParse('${json['estimated_price'] ?? json['ml_price_min'] ?? json['harga']}') ?? 0.0,
    );
  }
}