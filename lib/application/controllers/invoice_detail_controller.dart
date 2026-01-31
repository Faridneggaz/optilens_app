import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailController {
  static const String baseUrl = "http://192.168.100.20:8000/api/method/";
  static const String getInvoiceDetailsEndpoint = "mobile_app.api.get_single_invoice_details";

  Future<InvoiceDetailResponse?> fetchInvoiceDetails({
    required String invoiceName,
    String invoiceType = "Sales Invoice",
  }) async {
    final url = Uri.parse(
      "$baseUrl$getInvoiceDetailsEndpoint?invoice_name=$invoiceName",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['message'] != null) {
          // Vérifier si c'est une erreur
          if (jsonData['message']['error'] != null) {
            print('API Error: ${jsonData['message']['error']}');
            return null;
          }
          
          return InvoiceDetailResponse.fromJson(jsonData['message']);
        }
        
        return null;
      } else {
        print('Erreur serveur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur réseau: $e');
      return null;
    }
  }
}