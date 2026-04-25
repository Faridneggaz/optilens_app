import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/customer_response.dart';
import 'repository_exception.dart';

class CustomerRepository {
  Future<CustomerResponse> fetchCustomer(String code) async {
    final uri = Uri.parse(
      '${ApiConfig.mobileAppApiPath}get_client_by_code?code=$code',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return CustomerResponse.fromJson(json.decode(response.body));
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
