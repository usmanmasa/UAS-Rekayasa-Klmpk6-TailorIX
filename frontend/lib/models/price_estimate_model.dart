import 'json_helpers.dart';

class PriceEstimate {
  final double subtotalJasa;
  final double biayaPickup;
  final double biayaLayanan;
  final double totalEstimasi;
  // pickup breakdown
  final double? pickupDistanceKm;
  final double? pickupBaseFare;
  final double? pickupExtraFee;
  final double? pickupTotalOngkir;

  PriceEstimate({
    required this.subtotalJasa,
    required this.biayaPickup,
    required this.biayaLayanan,
    required this.totalEstimasi,
    this.pickupDistanceKm,
    this.pickupBaseFare,
    this.pickupExtraFee,
    this.pickupTotalOngkir,
  });

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    return PriceEstimate(
      subtotalJasa: parseDouble(json['subtotal_jasa']) ?? 0.0,
      biayaPickup: parseDouble(json['biaya_pickup']) ?? 0.0,
      biayaLayanan: parseDouble(json['biaya_layanan']) ?? 0.0,
      totalEstimasi: parseDouble(json['total_estimasi'] ?? json['estimated_price']) ?? 0.0,
      pickupDistanceKm: parseDouble(json['pickup_pricing']?['distance_km']) ?? parseDouble(json['pickup_distance_km']),
      pickupBaseFare: parseDouble(json['pickup_pricing']?['base_fare']),
      pickupExtraFee: parseDouble(json['pickup_pricing']?['extra_distance_fee']),
      pickupTotalOngkir: parseDouble(json['pickup_pricing']?['total_ongkir']),
    );
  }
}
