import '../entities/customer_response.dart';

abstract class CustomerRepository {
  Future<CustomerResponse> loginCustomer(String code);
  Future<void> logoutCustomer();
  Future<CustomerResponse> fetchCustomer(String code);

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
