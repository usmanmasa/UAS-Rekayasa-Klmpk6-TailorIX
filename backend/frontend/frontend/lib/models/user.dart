class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  String address;
  String role;
  String? photoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['phone_number'] ?? '',
      address: json['address'] ?? '',
      role: json['role'] ?? 'customer',
      photoUrl: json['photo_url'] ?? json['avatar'],
    );
  }
}
