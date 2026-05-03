import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/login_response.dart';
import 'repository_exception.dart';

class LoginRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _loginEndpoint = 'mobile_app.api.login';

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl$_loginEndpoint');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final message = jsonData['message'];
        if (message == null || message['ok'] == false) {
          final error = message?['error'] ?? 'Unknown error';
          throw RepositoryException('Login failed: $error');
        }
        return LoginResponse.fromJson(jsonData);
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
