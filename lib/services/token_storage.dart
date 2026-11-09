import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan rahasia (token JWT) memakai `flutter_secure_storage`.
///
/// Setting non-rahasia (tema, flag welcome) ada di `SettingsStore`
/// (`shared_preferences`).
class TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _key = 'auth_token';
  static const _timeout = Duration(seconds: 5);

  Future<void> save(String token) =>
      _storage.write(key: _key, value: token).timeout(_timeout);

  Future<String?> read() =>
      _storage.read(key: _key).timeout(_timeout, onTimeout: () => null);

  Future<void> clear() async {
    // Best-effort: kegagalan secure storage tidak boleh menghalangi logout.
    try {
      await _storage.delete(key: _key).timeout(_timeout);
    } catch (_) {}
  }
}
