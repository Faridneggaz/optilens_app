import 'customer.dart';

class CustomerResponse {
  final Customer customer;
  final String? sessionToken;

  CustomerResponse({required this.customer, this.sessionToken});
}
