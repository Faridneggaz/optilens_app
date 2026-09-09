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

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'],
      code: json['custom_customer_code'],
      debt: json['custom_debt'],
      email: json['email_id'],
      mobile: json['mobile_no'],
      priceList: json['default_price_list'] ?? "Standard",
    );
  }
}
