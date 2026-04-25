import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/invoices_response.dart';
import 'repository_exception.dart';

class InvoiceRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _getInvoicesByCustomerCode =
      'mobile_app.api.get_invoices_by_customer_code';

  Future<InvoicesResponse> fetchInvoices(
    String customerCode, {
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse(
      '$_baseUrl$_getInvoicesByCustomerCode?code=$customerCode&limit=$limit&offset=$offset',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return InvoicesResponse.fromJson(json.decode(response.body));
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
