import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService extends GetxService {
  late SharedPreferences _prefs;

  String get userCode => _prefs.getString('user_code') ?? '';
  String get userRole => _prefs.getString('user_role') ?? ''; 
  String get authToken => _prefs.getString('auth_token') ?? '';
  String getSid() => authToken;
  String get tokenExpiry => _prefs.getString('token_expiry') ?? '';

  Future<SessionService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> saveSession({
    required String code,
    required String role,
    required String token,
  }) async {
    await _prefs.setString('user_code', code);
    await _prefs.setString('user_role', role);
    await _prefs.setString('auth_token', token);
    
    // Set token expiry to 24 hours from now
    final expiry = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    await _prefs.setString('token_expiry', expiry);
  }

  Future<void> clearSession() async {
    await _prefs.remove('user_code');
    await _prefs.remove('user_role');
    await _prefs.remove('auth_token');
    await _prefs.remove('token_expiry');
    
    // Clear user permissions
    await _prefs.remove('allowed_companies');
    await _prefs.remove('allowed_warehouses');
    
    // Clear legacy keys to prevent corrupted state
    await _prefs.remove('custom_customer_code');
    await _prefs.remove('sid');
    await _prefs.remove('email');
    await _prefs.remove('name');
    await _prefs.remove('token');
  }

  bool isSessionValid() {
    final role = userRole;
    final expiryStr = tokenExpiry;
    
    // If no role has been set at all, it's invalid
    if (role.isEmpty || expiryStr.isEmpty) return false;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiryDate);
    } catch (_) {
      return false;
    }
  }

  Future<void> saveUserPermissions(List<String> companies, List<String> warehouses) async {
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
