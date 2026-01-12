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
    final url = Uri.parse(
      "$baseUrl$loginEndpoint?email=$email&password=$password",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LoginResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
