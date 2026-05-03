class User {
  final String sid;
  final String? email;
  final String? name;

  User({
    required this.sid,
    this.email,
    this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      sid: json['sid']?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString(),
    );
  }
}