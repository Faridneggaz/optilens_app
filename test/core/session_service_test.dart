import 'package:flutter_test/flutter_test.dart';
import 'package:optilens/core/services/session_service.dart';
import 'package:optilens/core/services/token_vault.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryTokenVault vault;
  late SessionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    vault = MemoryTokenVault();
    service = SessionService(tokenVault: vault, customerCodeVault: MemoryTokenVault());
  });

  test('migrates a SID from SharedPreferences into the vault', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'legacy-sid'});
    await service.init();

    expect(service.authToken, 'legacy-sid');
    expect(await vault.read(), 'legacy-sid');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
  });

  test('saveSession keeps the SID in the vault, not prefs', () async {
    await service.init();
    await service.saveSession(
      code: 'emp@x.com',
      role: 'user',
      token: 'sid-1',
      displayName: '  Farid Example  ',
    );

    expect(service.authToken, 'sid-1');
    expect(await vault.read(), 'sid-1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString('user_code'), 'emp@x.com');
    final restored = await SessionService(tokenVault: vault).init();
    expect(restored.userDisplayName, 'Farid Example');
    expect(restored.userCode, 'emp@x.com');
    await restored.clearSession();
    expect(restored.userDisplayName, isEmpty);
    expect(restored.isSessionValid(), isFalse);
  });

  test('an email is never used as a cached display name', () async {
    SharedPreferences.setMockInitialValues({
      'user_code': 'emp@x.com',
      'user_display_name': '  emp@x.com ',
    });
    await service.init();

    expect(service.userCode, 'emp@x.com');
    expect(service.userDisplayName, isEmpty);
    await service.saveUserDisplayName(' Farid Neggaz ');
    expect(service.userDisplayName, 'Farid Neggaz');
  });

  test('legacy customer login requires reauthentication after upgrade', () async {
    SharedPreferences.setMockInitialValues({
      'user_role': 'client',
      'user_code': 'old-personal-code',
      'token_expiry': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    });
    await service.init();
    expect(service.isSessionValid(), isFalse);
    expect((await SharedPreferences.getInstance()).containsKey('user_code'), isFalse);
  });

  test('restored customer session stays separate from the employee SID', () async {
    final codes = MemoryTokenVault();
    final first = await SessionService(tokenVault: vault, customerCodeVault: codes).init();
    await first.saveSession(code: 'personal', role: 'client', token: 'order-session');
    final restored = await SessionService(tokenVault: vault, customerCodeVault: codes).init();
    expect(restored.isSessionValid(), isTrue);
    expect(restored.userCode, 'personal');
    expect(restored.customerSession, 'order-session');
    expect(restored.authToken, isEmpty);
    await restored.clearSession();
    expect(await codes.read(), isNull);
  });

  test('clearSession wipes the vault and profile keys', () async {
    await service.init();
    await service.saveSession(code: 'C001', role: 'client', token: 'sid-2');
    expect(service.customerSession, 'sid-2');
    expect(service.getSid(), isEmpty);
    expect(service.userCode, 'C001');
    expect((await SharedPreferences.getInstance()).getString('user_code'), isNull);
    await service.clearSession();

    expect(service.authToken, isEmpty);
    expect(service.customerSession, isEmpty);
    expect(await vault.read(), isNull);
    expect(service.isSessionValid(), isFalse);
  });
}
