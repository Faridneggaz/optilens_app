// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/customer_response.dart';
import '../../domain/repositories/customer_repository.dart';
import '../mappers/json_mappers.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._client);

  final ApiClient _client;

  Future<CustomerResponse> fetchCustomer(String code) async {
    final json = await _client.getMobile(
      'get_client_by_code',
      query: {'code': code},
    );
    return CustomerResponseMapper.fromJson(json);
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final json = await _client.postMobile(
      'change_customer_code',
      query: {
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
