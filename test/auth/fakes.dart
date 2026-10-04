import 'package:bugarin_mobile/features/auth/data/auth_repository.dart';
import 'package:bugarin_mobile/features/auth/models/klien_profile.dart';
import 'package:bugarin_mobile/services/token_storage.dart';

/// TokenStorage in-memory — menghindari akses plugin platform di unit test.
class FakeTokenStorage extends TokenStorage {
  String? savedToken;
  bool cleared = false;

  void seed(String token) => savedToken = token;

  @override
  Future<void> save(String token) async => savedToken = token;

  @override
  Future<String?> read() async => savedToken;

  @override
  Future<void> clear() async {
    savedToken = null;
    cleared = true;
  }

  @override
  Future<bool> getHasSeenWelcome() async => false;

  @override
  Future<void> setHasSeenWelcome() async {}
}

/// Fake repository auth untuk menguji notifier tanpa network.
class FakeAuthRepository implements AuthRepository {
  AuthResult loginResult = const AuthResult(token: 'token', role: 'klien');
  AuthResult registerResult = const AuthResult(token: 'token', role: 'klien');

  KlienProfile? profile;
  AuthException? loginError;
  AuthException? registerError;
  AuthException? profileError;

  String? tokenToRead;
  bool logoutCalled = false;

  @override
  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult;
  }

  @override
  Future<AuthResult> register({
    required String nama,
    required String email,
    required String username,
    required String password,
  }) async {
    if (registerError != null) throw registerError!;
    return registerResult;
  }

  @override
  Future<KlienProfile> getProfile() async {
    if (profileError != null) throw profileError!;
    final current = profile;
    if (current == null) throw const AuthException('Profil tidak tersedia.');
    return current;
  }

  @override
  Future<String?> readToken() async => tokenToRead;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}
