import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_repository_provider.dart';
import '../features/auth/models/klien_profile.dart';

part 'auth_provider.g.dart';

sealed class AuthState {
  const AuthState();
}

/// State awal saat sesi masih di-restore (token belum divalidasi ke backend).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  final String role; // 'klien' | 'pt' | 'admin'
  final bool profileComplete;
  final KlienProfile? profile;
  const Authenticated({
    required this.role,
    required this.profileComplete,
    this.profile,
  });
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthUnknown();
  }

  /// Restore sesi nyata: bila ada token, validasi lewat `GET /klien/profile`
  /// untuk mengambil `profileComplete` (dipakai auth guard). Token tidak valid
  /// ditangani interceptor Dio (401 → logout) dan fallback di sini.
  Future<void> _restoreSession() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.readToken();
      if (token == null) {
        state = const Unauthenticated();
        return;
      }

      final profile = await repo.getProfile();
      state = Authenticated(
        role: profile.role ?? 'klien',
        profileComplete: profile.profileComplete,
        profile: profile,
      );
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  /// Login klien. Mengembalikan profil terbaru bila berhasil diambil.
  ///
  /// Melempar [AuthException] bila kredensial salah/tidak valid.
  Future<KlienProfile?> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).login(
          emailOrUsername: emailOrUsername,
          password: password,
        );
    return _applyAuthResult(result);
  }

  /// Registrasi klien baru (khusus role klien).
  Future<KlienProfile?> register({
    required String nama,
    required String email,
    required String username,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).register(
          nama: nama,
          email: email,
          username: username,
          password: password,
        );
    return _applyAuthResult(result);
  }

  Future<KlienProfile?> _applyAuthResult(AuthResult result) async {
    // Token sudah tersimpan; langsung tandai login walau profil belum sempat di-fetch.
    state = Authenticated(role: result.role, profileComplete: false);

    try {
      final profile = await ref.read(authRepositoryProvider).getProfile();
      state = Authenticated(
        role: result.role,
        profileComplete: profile.profileComplete,
        profile: profile,
      );
      return profile;
    } on AuthException {
      // Tetap terautentikasi; profil bisa di-fetch ulang nanti.
      return null;
    }
  }

  void loginSuccess({required String role, required bool profileComplete}) {
    state = Authenticated(role: role, profileComplete: profileComplete);
  }

  void markProfileComplete() {
    final current = state;
    if (current is Authenticated) {
      state = Authenticated(
        role: current.role,
        profileComplete: true,
        profile: current.profile,
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Unauthenticated();
  }
}
