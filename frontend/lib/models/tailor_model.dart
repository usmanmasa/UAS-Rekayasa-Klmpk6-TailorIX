import 'json_helpers.dart';
import 'review_model.dart';

class Tailor {
  final int id;
  final String shopName;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double ratingAvg;
  final int ratingCount;
  final List<String>? skills;
  final List<String>? images;
  final List<Map<String, dynamic>>? imagesMeta;
  final List<TailorReview>? reviews;

  Tailor({
    required this.id,
    required this.shopName,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.ratingAvg,
    required this.ratingCount,
    this.skills,
    this.images,
    this.imagesMeta,
    this.reviews,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) {
    return Tailor(
      id: json['id'],
      shopName: json['shop_name'] ?? '',
      description: json['description'],
      address: json['address'],
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      ratingAvg: parseDouble(json['rating_avg']) ?? 0,
      ratingCount: parseInt(json['rating_count']) ?? 0,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e['name'] as String).toList(),
        images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
        imagesMeta: (json['images_meta'] as List<dynamic>?)
          ?.map((e) => (e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => TailorReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
