import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_vault.dart';

class SessionService extends GetxService {
  SessionService({TokenVault? tokenVault})
      : _tokenVault = tokenVault ?? SecureTokenVault();

  late SharedPreferences _prefs;
  final TokenVault _tokenVault;
  String _authToken = '';

  String get userCode => _prefs.getString('user_code') ?? '';
  String get userRole => _prefs.getString('user_role') ?? '';
  String get authToken => _authToken;
  String getSid() => _authToken;
  String get tokenExpiry => _prefs.getString('token_expiry') ?? '';

  Future<SessionService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyToken();
    try {
      _authToken = await _tokenVault.read() ?? '';
    } catch (_) {
      _authToken = '';
    }
    return this;
  }

  /// Moves a SID previously stored in SharedPreferences into the vault.
  Future<void> _migrateLegacyToken() async {
    for (final key in const ['auth_token', 'sid', 'token']) {
      final legacy = _prefs.getString(key);
      if (legacy == null || legacy.isEmpty) continue;
      await _tokenVault.write(legacy);
      await _prefs.remove(key);
      break;
    }
  }

  Future<void> saveSession({
    required String code,
    required String role,
    required String token,
  }) async {
    await _prefs.setString('user_code', code);
    await _prefs.setString('user_role', role);
    await _persistToken(token);

    final expiry =
        DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    await _prefs.setString('token_expiry', expiry);
  }

  Future<void> _persistToken(String token) async {
    _authToken = token;
    if (token.isEmpty) {
      await _tokenVault.delete();
    } else {
      await _tokenVault.write(token);
    }
  }

  Future<void> clearSession() async {
    _authToken = '';
    await _tokenVault.delete();
    await _prefs.remove('user_code');
    await _prefs.remove('user_role');
    await _prefs.remove('auth_token');
    await _prefs.remove('token_expiry');

    await _prefs.remove('allowed_companies');
    await _prefs.remove('allowed_warehouses');

    await _prefs.remove('custom_customer_code');
    await _prefs.remove('sid');
    await _prefs.remove('email');
    await _prefs.remove('name');
    await _prefs.remove('token');
  }

  bool isSessionValid() {
    final role = userRole;
    final expiryStr = tokenExpiry;

    if (role.isEmpty || expiryStr.isEmpty) return false;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiryDate);
    } catch (_) {
      return false;
    }
  }

  Future<void> saveUserPermissions(
    List<String> companies,
    List<String> warehouses,
  ) async {
    await _prefs.setStringList('allowed_companies', companies);
    await _prefs.setStringList('allowed_warehouses', warehouses);
  }

  List<String> getAllowedCompanies() {
    return _prefs.getStringList('allowed_companies') ?? [];
  }

  List<String> getAllowedWarehouses() {
    return _prefs.getStringList('allowed_warehouses') ?? [];
  }

  bool hasCompanyRestriction() {
    return getAllowedCompanies().isNotEmpty;
  }

  bool hasWarehouseRestriction() {
    return getAllowedWarehouses().isNotEmpty;
  }
}
