class Customer {
  final String name;
  final String code;
  final double debt;
  final String? email;
  final String? mobile;
  final String priceList;

  Customer({
    required this.name,
    required this.code,
    required this.debt,
    this.email,
    this.mobile,
    required this.priceList,
  });
}
