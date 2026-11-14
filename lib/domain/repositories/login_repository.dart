import '../entities/login_response.dart';

abstract class LoginRepository {
  Future<String> fetchUserDisplayName(String token);
  Future<LoginResponse> login({
    required String email,
    required String password,
  });
}
