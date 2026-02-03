import 'user.dart';

class LoginResponse {
  final User user;

  LoginResponse({required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'];

    if (message is! Map<String, dynamic>) {
      throw Exception('Login failed');
    }

    return LoginResponse(
      user: User.fromJson(message),
    );
  }
}
