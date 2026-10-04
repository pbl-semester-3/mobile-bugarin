import '../providers/auth_provider.dart';

/// Logika redirect auth guard — fungsi murni supaya bisa di-unit-test
/// tanpa widget test (lihat `test/router/auth_redirect_test.dart`).
///
/// Mengembalikan path tujuan, atau `null` bila tidak perlu redirect.
String? resolveAuthRedirect({
  required AuthState authState,
  required bool hasSeenWelcome,
  required String location,
}) {
  const authRoutes = {'/login', '/register'};

  // Sesi masih dipulihkan → tahan di splash sampai status jelas.
  if (authState is AuthUnknown) {
    return location == '/splash' ? null : '/splash';
  }

  final isLoggedIn = authState is Authenticated;
  final isProfileComplete =
      authState is Authenticated && authState.profileComplete;

  // Belum login.
  if (!isLoggedIn) {
    // Welcome hanya untuk pembukaan app pertama kali.
    if (!hasSeenWelcome) {
      return location == '/welcome' ? null : '/welcome';
    }
    return authRoutes.contains(location) ? null : '/login';
  }

  // Sudah login tapi profil/siklus belum lengkap → paksa Onboarding.
  if (!isProfileComplete) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  // Sudah login + lengkap: jangan biarkan balik ke halaman auth/welcome.
  // `/onboarding` tetap diizinkan (dipakai alur "mulai target baru").
  if (location == '/login' ||
      location == '/register' ||
      location == '/welcome' ||
      location == '/splash') {
    return '/';
  }

  return null;
}
