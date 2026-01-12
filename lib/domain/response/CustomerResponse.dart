import 'Customer.dart';

class CustomerResponse {
  final Customer customer;

  CustomerResponse({required this.customer});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    final customerJson = json['message']['customer'];
    if (customerJson == null) {
      throw Exception("Customer data not found");
    }
    return CustomerResponse(customer: Customer.fromJson(customerJson));
  }
}
