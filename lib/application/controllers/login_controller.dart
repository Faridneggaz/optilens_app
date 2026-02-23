import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/login_response.dart';

class LoginController {
  static const String baseUrl = "https://optilens.jethings.com/api/method/";
  static const String loginEndpoint = "mobile_app.api.login";

  Future<LoginResponse?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl$loginEndpoint").replace(
      queryParameters: {
        'email': email,
        'password': password,
      },
    );

    try {
      print('🔵 LOGIN REQUEST: $url');
      final response = await http.get(url);

      print('Status Code: ${response.statusCode}');
      print('Response Body RAW: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('JSON Decoded: $jsonData');

        final message = jsonData['message'];

        if (message == null || message['ok'] == false) {
          final error = message?['error'] ?? 'Erreur inconnue';
          print(' Échec login: $error');
          return null;
        }

        final loginResponse = LoginResponse.fromJson(jsonData);
        print('LoginResponse créé - Username: ${loginResponse.user.name}');
        print('LoginResponse créé - SID: ${loginResponse.user.sid}');

        return loginResponse;
      } else {
        print(' Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print(' Exception dans login: $e');
      return null;
    }
  }
}