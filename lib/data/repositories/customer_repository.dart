import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/customer_response.dart';
import '../../core/services/session_service.dart';
import 'package:get/get.dart';
import 'repository_exception.dart';

class CustomerRepository {
  Future<CustomerResponse> fetchCustomer(String code) async {
    final token = Get.find<SessionService>().getSid();
    final uri = Uri.parse(
      '${ApiConfig.mobileAppApiPath}get_client_by_code?code=$code&token=$token',
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

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = Get.find<SessionService>().getSid();
    final url = Uri.parse(
      'https://optilens.jethings.com/api/method/mobile_app.api.change_customer_code'
      '?old_code=${Uri.encodeComponent(oldPassword)}'
      '&new_code=${Uri.encodeComponent(newPassword)}'
      '&token=$token',
    );
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // API wraps response in 'message' key
        final data = body['message'];
        if (data == null) {
          return {'success': false, 'error': 'Empty response'};
        }
        return Map<String, dynamic>.from(data as Map);
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
