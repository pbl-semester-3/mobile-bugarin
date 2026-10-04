import 'package:bugarin_mobile/providers/auth_provider.dart';
import 'package:bugarin_mobile/router/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unknown = AuthUnknown();
  const unauth = Unauthenticated();
  const incomplete = Authenticated(role: 'klien', profileComplete: false);
  const complete = Authenticated(role: 'klien', profileComplete: true);

  group('AuthUnknown (sesi masih direstore)', () {
    test('dari halaman mana pun -> splash', () {
      expect(
        resolveAuthRedirect(
            authState: unknown, hasSeenWelcome: false, location: '/'),
        '/splash',
      );
    });

    test('tetap di splash', () {
      expect(
        resolveAuthRedirect(
            authState: unknown, hasSeenWelcome: true, location: '/splash'),
        isNull,
      );
    });
  });

  group('Belum login', () {
    test('belum pernah buka app -> welcome', () {
      expect(
        resolveAuthRedirect(
            authState: unauth, hasSeenWelcome: false, location: '/'),
        '/welcome',
      );
    });

    test('di welcome -> tetap', () {
      expect(
        resolveAuthRedirect(
            authState: unauth, hasSeenWelcome: false, location: '/welcome'),
        isNull,
      );
    });

    test('sudah pernah buka app -> login', () {
      expect(
        resolveAuthRedirect(
            authState: unauth, hasSeenWelcome: true, location: '/'),
        '/login',
      );
    });

    test('di login -> tetap', () {
      expect(
        resolveAuthRedirect(
            authState: unauth, hasSeenWelcome: true, location: '/login'),
        isNull,
      );
    });

    test('di /register (route sudah dihapus) -> login', () {
      expect(
        resolveAuthRedirect(
            authState: unauth, hasSeenWelcome: true, location: '/register'),
        '/login',
      );
    });
  });

  group('Login, profil belum lengkap', () {
    test('dari beranda -> onboarding', () {
      expect(
        resolveAuthRedirect(
            authState: incomplete, hasSeenWelcome: true, location: '/'),
        '/onboarding',
      );
    });

    test('di onboarding -> tetap', () {
      expect(
        resolveAuthRedirect(
            authState: incomplete,
            hasSeenWelcome: true,
            location: '/onboarding'),
        isNull,
      );
    });
  });

  group('Login, profil lengkap', () {
    test('dari login -> beranda', () {
      expect(
        resolveAuthRedirect(
            authState: complete, hasSeenWelcome: true, location: '/login'),
        '/',
      );
    });

    test('dari welcome -> beranda', () {
      expect(
        resolveAuthRedirect(
            authState: complete, hasSeenWelcome: true, location: '/welcome'),
        '/',
      );
    });

    test('di beranda -> tetap', () {
      expect(
        resolveAuthRedirect(
            authState: complete, hasSeenWelcome: true, location: '/'),
        isNull,
      );
    });

    test('di onboarding tetap diizinkan (alur mulai target baru)', () {
      expect(
        resolveAuthRedirect(
            authState: complete,
            hasSeenWelcome: true,
            location: '/onboarding'),
        isNull,
      );
    });
  });
}
