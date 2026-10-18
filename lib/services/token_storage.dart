import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan rahasia (token JWT) memakai `flutter_secure_storage`.
///
/// Setting non-rahasia (tema, flag welcome) ada di `SettingsStore`
/// (`shared_preferences`).
class TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _key = 'auth_token';

  Future<void> save(String token) => _storage.write(key: _key, value: token);
  Future<String?> read() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}