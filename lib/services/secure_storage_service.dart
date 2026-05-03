import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores and retrieves API keys securely using the platform keychain /
/// keystore (flutter_secure_storage).
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _keyFor(String provider) => 'api_key_$provider';

  Future<void> saveApiKey(String provider, String key) async {
    await _storage.write(key: _keyFor(provider), value: key);
  }

  Future<String?> getApiKey(String provider) async {
    return _storage.read(key: _keyFor(provider));
  }

  Future<void> deleteApiKey(String provider) async {
    await _storage.delete(key: _keyFor(provider));
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
