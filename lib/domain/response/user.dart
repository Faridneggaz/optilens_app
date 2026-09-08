class User {
  final String sid;
  final String? email;
  final String? name;
  final List<String> allowedCompanies;
  final List<String> allowedWarehouses;

  User({
    required this.sid,
    this.email,
    this.name,
    this.allowedCompanies = const [],
    this.allowedWarehouses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      sid: json['sid']?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      allowedCompanies: (json['allowed_companies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allowedWarehouses: (json['allowed_warehouses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}