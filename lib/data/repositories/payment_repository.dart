import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/payment_response.dart';
import 'repository_exception.dart';

class PaymentRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _getPaymentsByCustomerCode =
      'mobile_app.api.get_payments_by_customer_code';

  Future<PaymentResponse> fetchPayments(String customerCode) async {
    final url = Uri.parse(
      '$_baseUrl$_getPaymentsByCustomerCode?code=$customerCode',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return PaymentResponse.fromJson(json.decode(response.body));
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
