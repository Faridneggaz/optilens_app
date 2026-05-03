import 'user.dart';

class LoginResponse {
  final User user;

  LoginResponse({required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'];

    if (message is! Map<String, dynamic>) {
      throw Exception('Login failed - Invalid response format');
    }

    final userData = message['user'];

    if (userData is! Map<String, dynamic>) {
      throw Exception('Login failed - Invalid user data format');
    }

    final user = User.fromJson(userData);

    return LoginResponse(user: user);
  }
}