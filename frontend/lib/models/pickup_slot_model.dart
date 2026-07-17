class PickupSlotOption {
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String status;

  PickupSlotOption({
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
  });

  factory PickupSlotOption.fromJson(Map<String, dynamic> json) {
    return PickupSlotOption(
      tanggal: json['tanggal'] as String,
      jamMulai: json['jam_mulai'] as String,
      jamSelesai: json['jam_selesai'] as String,
      status: json['status'] as String,
    );
  }

  String get label => '$jamMulai - $jamSelesai';
}
