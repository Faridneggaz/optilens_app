import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the ERP session SID outside of SharedPreferences.
abstract class TokenVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureTokenVault implements TokenVault {
  SecureTokenVault({FlutterSecureStorage? storage, this.key = 'auth_token'})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final String key;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: key);

  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: key);
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
