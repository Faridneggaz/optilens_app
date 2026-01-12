class Customer {
  final String name;
  final String code;
  final double debt;
  final String? email;
  final String? mobile;

  Customer({
    required this.name,
    required this.code,
    required this.debt,
    this.email,
    this.mobile,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'],
      code: json['custom_customer_code'],
      debt: json['custom_debt'],
      email: json['email_id'],
      mobile: json['mobile_no'],
    );
  }
}
