import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/response/invoice_detail_response.dart';

class InvoiceDetailController {
  static const String baseUrl = "http://192.168.100.20:8000/api/method/";
  
  Future<InvoiceDetailResponse?> getInvoiceDetails({
    required String invoiceName,
    String invoiceType = "Sales Invoice",
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/method/votre_app.api.get_invoice_details');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invoice_name': invoiceName,
          'invoice_type': invoiceType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          return InvoiceDetailResponse.fromJson(data['message']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching invoice details: $e');
      return null;
    }
  }
}