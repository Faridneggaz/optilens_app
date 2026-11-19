import '../entities/customer_response.dart';

abstract class CustomerRepository {
  Future<CustomerResponse> loginCustomer(String code);
  Future<void> logoutCustomer();
  /// The session identifies the customer. The stored code is only used locally.
  Future<CustomerResponse> fetchCustomer(String storedCode);

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
