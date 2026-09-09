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
}
