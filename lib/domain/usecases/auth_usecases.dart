import '../entities/customer_response.dart';
import '../entities/login_response.dart';
import '../repositories/customer_repository.dart';
import '../repositories/login_repository.dart';
import '../results/action_result.dart';

class AuthUseCases {
  AuthUseCases(this._login, this._customers);
  final LoginRepository _login;
  final CustomerRepository _customers;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final result = await _login.login(email: email, password: password);
    if (result.user.sid.isEmpty) {
      throw const MissingTokenException();
    }
    return result;
  }

  Future<CustomerResponse> fetchCustomer(String code) =>
      _customers.fetchCustomer(code);

  Future<ChangeCodeResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final map = await _customers.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return ChangeCodeResult(
      success: map['success'] == true,
      error: map['error']?.toString(),
    );
  }
}
