import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/PaymentResponse.dart';

class PaymentController {
  static const String baseUrl = "https://optilens.jethings.com/api/method/";
  static const String getPaymentsByCustomerCode =
      "mobile_app.api.get_payments_by_customer_code";

  Future<PaymentResponse?> fetchPayments(String customerCode) async {
    final url = Uri.parse(
      "$baseUrl$getPaymentsByCustomerCode?code=$customerCode",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PaymentResponse.fromJson(jsonData);
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
