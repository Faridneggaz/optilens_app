import '../../core/network/api_client.dart';
import '../../domain/response/login_response.dart';
import 'repository_exception.dart';

class LoginRepository {
  LoginRepository(this._client);

  final ApiClient _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final jsonData = await _client.postMobile(
      'login',
      body: {'email': email, 'password': password},
      attachToken: false,
    );
    final message = jsonData['message'];
    if (message is Map && message['user'] is Map) {
      return LoginResponse.fromJson(jsonData);
    }
    if (message == null || message['ok'] == false) {
      final error =
          (message is Map ? message['error'] : null) ?? 'Unknown error';
      throw RepositoryException('Login failed: $error');
    }
    return LoginResponse.fromJson(jsonData);
  }
}
