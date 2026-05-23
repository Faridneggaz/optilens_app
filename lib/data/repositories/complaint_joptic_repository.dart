import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 

class ComplaintRepository {
  final String _apiUrl = 'https://erp.jethings.com/api/resource/reclamtion client';

  Future<http.Response> submitComplaint({
    required String clientName,
    required String description,
  }) async {
    return await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'token b70ed3816bf7925:7eeea71d843b299',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client': clientName, 
        'desciption_reclamation': description, 
        'date_reception': DateFormat('yyyy-MM-dd').format(DateTime.now()), 
      }),
    );
  }
}