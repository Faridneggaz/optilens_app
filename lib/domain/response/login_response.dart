import 'user.dart';

class LoginResponse {
  final User user;
  final String full_name;

  LoginResponse({required this.user, required this.full_name});

  static LoginResponse fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json["message"]["user"]),
      full_name: json["full_name"],
    );
  }
}
