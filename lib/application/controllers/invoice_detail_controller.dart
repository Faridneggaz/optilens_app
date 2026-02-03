import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailController {
  static const String baseUrl = "https://optilens.jethings.com//api/method/";
  
  Future<InvoiceDetailResponse?> getInvoiceDetails({
    required String invoiceName,
    String invoiceType = "Sales Invoice",
  }) async {
    try {
     
      final url = Uri.parse('${baseUrl}mobile_app.api.get_single_invoice_details');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invoice_name': invoiceName, // Paramètre attendu par votre def dans api.py
        }),
      );

      print('Status Code: ${response.statusCode}'); // Debug
      print('Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Frappe/ERPNext renvoie toujours les données dans l'objet 'message'
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