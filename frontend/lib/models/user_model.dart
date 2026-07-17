class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? photo;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photo,
    required this.isVerified,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'pelanggan',
      phone: json['phone'],
      photo: json['photo'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }
}
