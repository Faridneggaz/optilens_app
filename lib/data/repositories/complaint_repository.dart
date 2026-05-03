import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import 'repository_exception.dart';

class ComplaintRepository {
  static const String _baseUrl = ApiConfig.mobileAppApiPath;

  /// Throws [RepositoryException] on failure.
  Future<void> submitComplaint({
    required String client,
    required String description,
  }) async {
    final url = Uri.parse('${_baseUrl}create_customer_complaint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'client': client, 'description': description}),
      );
      if (response.statusCode != 200) {
        throw RepositoryException(
            'Server error: ${response.statusCode} – ${response.body}');
      }
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
