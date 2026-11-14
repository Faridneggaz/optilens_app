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
    service = SessionService(tokenVault: vault);
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

  test('clearSession wipes the vault and profile keys', () async {
    await service.init();
    await service.saveSession(code: 'C001', role: 'client', token: 'sid-2');
    await service.clearSession();

    expect(service.authToken, isEmpty);
    expect(await vault.read(), isNull);
    expect(service.isSessionValid(), isFalse);
  });
}
