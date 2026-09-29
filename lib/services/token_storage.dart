import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _key = 'auth_token';
  static const _hasSeenWelcomeKey = 'has_seen_welcome';

  Future<void> save(String token) => _storage.write(key: _key, value: token);
  Future<String?> read() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);

  Future<bool> getHasSeenWelcome() async {
    final value = await _storage.read(key: _hasSeenWelcomeKey);
    return value == 'true';
  }

  Future<void> setHasSeenWelcome() =>
      _storage.write(key: _hasSeenWelcomeKey, value: 'true');
}