import 'dart:convert';
import 'package:http/http.dart' as http;

class ComplaintController {
 
  static const String baseUrl = "http://192.168.0.100:8000/api/method/mobile_app.api.";

  Future<bool> submitComplaint({
    required String client,
    required String description,
  }) async {
    final url = Uri.parse("${baseUrl}create_customer_complaint");
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": client,
          "description": description,
          
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] == "Success";
      }
      return false;
    } catch (e) {
      print("Erreur réseau réclamation: $e");
      return false;
    }
  }
}