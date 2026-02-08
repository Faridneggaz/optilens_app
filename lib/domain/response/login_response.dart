import 'user.dart';

class LoginResponse {
  final User user;

  LoginResponse({required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('🔵 LoginResponse.fromJson - JSON reçu: $json');
    
    final message = json['message'];
    print('🔵 Message extrait: $message');

    if (message is! Map<String, dynamic>) {
      print('❌ Message n\'est pas un Map<String, dynamic>');
      throw Exception('Login failed - Invalid response format');
    }

    // ✅ CORRECTION: Le user est dans message['user'] !
    final userData = message['user'];
    print('🔵 UserData extrait: $userData');

    if (userData is! Map<String, dynamic>) {
      print('❌ UserData n\'est pas un Map<String, dynamic>');
      throw Exception('Login failed - Invalid user data format');
    }

    print('🔵 Création du User à partir de: $userData');
    final user = User.fromJson(userData);
    print('🔵 User créé - SID: ${user.sid}, Name: ${user.name}, Email: ${user.email}');

    return LoginResponse(user: user);
  }
}