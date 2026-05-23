import 'package:http/http.dart' as http;
import 'dart:convert';

class LeadRepository {
  final String _apiUrl = 'https://erp.jethings.com/api/resource/Lead';

  Future<http.Response> createLead({required String name, required String phone}) async {
    return await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'token b70ed3816bf7925:7eeea71d843b299',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'lead_name': name,
        'company_name': name,
        'mobile_no': phone,
        //'source': 'Mobile App',
        'status': 'Lead',
        'description': 'Demande d\'abonnement via l\'application mobile J-Optic'
      }),
    );
  }
}