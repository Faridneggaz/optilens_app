// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/customer_response.dart';
import '../../domain/repositories/customer_repository.dart';
import '../mappers/json_mappers.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._client);

  final ApiClient _client;

  Future<CustomerResponse> loginCustomer(String code) async {
    final json = await _client.postMobile('login_customer', body: {'code': code}, attachToken: false);
    _client.unwrap(json);
    return CustomerResponseMapper.fromJson(json, code: code);
  }

  Future<void> logoutCustomer() async {
    await _client.postCustomerMethod('logout_customer');
  }

  Future<CustomerResponse> fetchCustomer(String storedCode) async {
    final json = await _client.getCustomerMethod('get_customer_profile');
    _client.unwrap(json);
    return CustomerResponseMapper.fromJson(json, code: storedCode);
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final json = await _client.postMobile(
      'change_customer_code',
      attachToken: false,
      body: {
        'old_code': oldPassword,
        'new_code': newPassword,
      },
    );
    final data = json['message'];
    if (data == null) {
      return {'success': false, 'error': 'Empty response'};
    }
    return Map<String, dynamic>.from(data as Map);
  }
}
