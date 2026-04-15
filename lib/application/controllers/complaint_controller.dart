import 'dart:convert';
import 'package:http/http.dart' as http;

class ComplaintController {
 
  static const String baseUrl = "http://192.168.0.104:8000/api/method/mobile_app.api.";

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

      print("Complaint response [${response.statusCode}]: ${response.body}");

      // Frappe returns the created document in data['message'], not the string "Success".
      // Any HTTP 200 means the record was saved successfully.
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur réseau réclamation: $e");
      return false;
    }
  }
}