import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/invoice_detail_response.dart';
import 'repository_exception.dart';

class InvoiceDetailRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;

  Future<InvoiceDetailResponse> getInvoiceDetails({
    required String invoiceName,
  }) async {
    final url = Uri.parse('${_baseUrl}mobile_app.api.get_single_invoice_details');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'invoice_name': invoiceName}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          return InvoiceDetailResponse.fromJson(data['message']);
        }
        throw const RepositoryException('Empty message in response');
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
