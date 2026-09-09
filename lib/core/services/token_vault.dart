import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the ERP session SID outside of SharedPreferences.
abstract class TokenVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureTokenVault implements TokenVault {
  SecureTokenVault({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// In-memory vault for unit tests.
class MemoryTokenVault implements TokenVault {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> delete() async => _value = null;
}
