import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/InvoicesResponse.dart';

class InvoiceController {
  static const String baseUrl = "https://optilens.jethings.com/api/method/";
  static const String getInvoicesByCustomerCode = "mobile_app.api.get_invoices_by_customer_code";

  Future<InvoicesResponse?> fetchInvoices(
    String customerCode, {
    int limit = 20,
    int offset = 0, 
  }) async {
    final url = Uri.parse(
      "$baseUrl$getInvoicesByCustomerCode?code=$customerCode&limit=$limit&offset=$offset",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return InvoicesResponse.fromJson(jsonData);
      } else {
        print("Erreur serveur: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return null;
    }
  }
}