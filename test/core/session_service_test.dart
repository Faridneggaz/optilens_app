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
    await service.saveSession(code: 'emp@x.com', role: 'user', token: 'sid-1');

    expect(service.authToken, 'sid-1');
    expect(await vault.read(), 'sid-1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString('user_code'), 'emp@x.com');
    expect(service.isSessionValid(), isTrue);
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
