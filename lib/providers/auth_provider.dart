import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/token_storage.dart';

part 'auth_provider.g.dart';

sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  final String role; // 'klien' | 'pt' | 'admin'
  final bool profileComplete;
  const Authenticated({required this.role, required this.profileComplete});
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() {
    _restoreSession();
    return const Unauthenticated();
  }

  Future<void> _restoreSession() async {
    final token = await TokenStorage().read();
    if (token == null) return;
    // TODO: panggil GET /klien/profile untuk cek profileComplete sesungguhnya
    // (lihat Bugarin_PRD_Mobile.md bab 2 - Auth guard logic).
    state = const Authenticated(role: 'klien', profileComplete: false);
  }

  void loginSuccess({required String role, required bool profileComplete}) {
    state = Authenticated(role: role, profileComplete: profileComplete);
  }

  void markProfileComplete() {
    final current = state;
    if (current is Authenticated) {
      state = Authenticated(role: current.role, profileComplete: true);
    }
  }

  Future<void> logout() async {
    await TokenStorage().clear();
    state = const Unauthenticated();
  }
}
