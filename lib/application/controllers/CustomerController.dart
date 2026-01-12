import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/CustomerResponse.dart';

class CustomerController {
  Future<CustomerResponse?> fetchCustomer(String code) async {
    try {
      final uri = Uri.parse(
        'https://optilens.jethings.com/api/method/mobile_app.api.get_client_by_code?code=$code',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CustomerResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
