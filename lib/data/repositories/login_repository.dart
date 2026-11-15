// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/login_repository.dart';
import '../mappers/json_mappers.dart';

class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl(this._client);

  final ApiClient _client;

  Future<String> fetchUserDisplayName(String token) async {
    final response = await _client.postMobile(
      'get_my_user_name',
      attachToken: false,
      body: {'token': token},
    );
    final message = response['message'];
    return message is Map ? (message['name']?.toString().trim() ?? '') : '';
  }

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
      return LoginResponseMapper.fromJson(jsonData);
    }
    if (message == null || message['ok'] == false) {
      final error =
          (message is Map ? message['error'] : null) ?? 'Unknown error';
      throw RepositoryException('Login failed: $error');
    }
    return LoginResponseMapper.fromJson(jsonData);
  }
}
