import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/payment_response.dart';
import 'repository_exception.dart';

class PaymentRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _getPaymentsByCustomerCode =
      'mobile_app.api.get_payments_by_customer_code';
  static const int pageSize = 20;

  Future<PaymentResponse> fetchPayments(
    String customerCode, {
    int limit  = pageSize,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    String urlStr = '$_baseUrl$_getPaymentsByCustomerCode?code=$customerCode&limit=$limit&offset=$offset';
    if (searchText != null && searchText.isNotEmpty) {
      urlStr += '&search_text=$searchText';
    }
    if (status != null && status != 'All') {
      urlStr += '&status=$status';
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return PaymentResponse.fromJson(
          json.decode(response.body),
          limit,
        );
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}