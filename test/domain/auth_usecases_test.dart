import 'package:flutter_test/flutter_test.dart';
import 'package:optilens/domain/entities/customer_response.dart';
import 'package:optilens/domain/entities/login_response.dart';
import 'package:optilens/domain/entities/user.dart';
import 'package:optilens/domain/repositories/customer_repository.dart';
import 'package:optilens/domain/repositories/login_repository.dart';
import 'package:optilens/domain/failures/failures.dart';
import 'package:optilens/domain/results/action_result.dart';
import 'package:optilens/domain/usecases/usecases.dart';

class _FakeLoginRepository implements LoginRepository {
  _FakeLoginRepository(this._response);
  final LoginResponse _response;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async =>
      _response;
}

class _FakeCustomerRepository implements CustomerRepository {
  @override
  Future<CustomerResponse> fetchCustomer(String code) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      {'success': true};
}

void main() {
  group('ActionResult', () {
    test('maps a material_request document name', () {
      final result = ActionResult.fromApiMap({
        'success': true,
        'material_request': 'MAT-MR-2026-0001',
      });
      expect(result.isSuccess, isTrue);
      expect(result.documentName, 'MAT-MR-2026-0001');
    });

    test('maps a Frappe success payload', () {
      final result = ActionResult.fromApiMap({
        'message': 'Success',
        'detail': 'ok',
      });
      expect(result.isSuccess, isTrue);
      expect(result.detail, 'ok');
    });

    test('maps an error payload', () {
      final result = ActionResult.fromApiMap({'error': 'boom'});
      expect(result.isSuccess, isFalse);
      expect(result.error, 'boom');
    });

    test('fromException marks session errors as auth-handled', () {
      final result = ActionResult.fromException(const InvalidSessionException());
      expect(result.isAuthHandled, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('extracts a stock entry id and ignores material request names', () {
      final result = ActionResult.fromApiMap({
        'success': true,
        'stock_entry_id': 'MAT-STE-2026-0004',
        'name': 'MAT-MR-2026-0001',
      });
      expect(result.isSuccess, isTrue);
      expect(result.navigableStockEntryId, 'MAT-STE-2026-0004');
    });
  });

  group('AuthUseCases', () {
    test('rejects a login without SID', () async {
      final useCases = AuthUseCases(
        _FakeLoginRepository(LoginResponse(user: User(sid: ''))),
        _FakeCustomerRepository(),
      );

      expect(
        () => useCases.login(email: 'a', password: 'b'),
        throwsA(isA<MissingTokenException>()),
      );
    });

    test('returns the login payload when SID is present', () async {
      final useCases = AuthUseCases(
        _FakeLoginRepository(
          LoginResponse(user: User(sid: 'sid-1', email: 'a@b.c')),
        ),
        _FakeCustomerRepository(),
      );

      final result = await useCases.login(email: 'a', password: 'b');
      expect(result.user.sid, 'sid-1');
    });
  });
}
