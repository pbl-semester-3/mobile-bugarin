import 'package:bugarin_mobile/features/auth/data/auth_repository.dart';
import 'package:bugarin_mobile/features/auth/data/auth_repository_provider.dart';
import 'package:bugarin_mobile/features/auth/models/klien_profile.dart';
import 'package:bugarin_mobile/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

KlienProfile _profile({required bool complete}) => KlienProfile(
      id: 1,
      userId: 10,
      nama: 'Maya',
      profileComplete: complete,
    );

ProviderContainer _container(FakeAuthRepository fake) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  // Jaga provider tetap hidup selama test (autoDispose).
  container.listen(authStateProvider, (_, __) {});
  return container;
}

void main() {
  test('login sukses -> Authenticated dengan profileComplete dari profil', () async {
    final fake = FakeAuthRepository()
      ..loginResult = const AuthResult(token: 't', role: 'klien')
      ..profile = _profile(complete: true);
    final container = _container(fake);

    final profile = await container
        .read(authStateProvider.notifier)
        .login(emailOrUsername: 'a', password: 'b');

    final state = container.read(authStateProvider);
    expect(profile?.profileComplete, isTrue);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).role, 'klien');
    expect(state.profileComplete, isTrue);
    expect(state.profile?.nama, 'Maya');
  });

  test('login gagal -> state tetap Unauthenticated', () async {
    final fake = FakeAuthRepository()..loginError = const AuthException('salah');
    final container = _container(fake);

    await expectLater(
      container
          .read(authStateProvider.notifier)
          .login(emailOrUsername: 'a', password: 'b'),
      throwsA(isA<AuthException>()),
    );

    expect(container.read(authStateProvider), isA<Unauthenticated>());
  });

  test('login sukses tapi fetch profil gagal -> tetap Authenticated', () async {
    final fake = FakeAuthRepository()
      ..loginResult = const AuthResult(token: 't', role: 'klien')
      ..profileError = const AuthException('offline');
    final container = _container(fake);

    final profile = await container
        .read(authStateProvider.notifier)
        .login(emailOrUsername: 'a', password: 'b');

    final state = container.read(authStateProvider);
    expect(profile, isNull);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).profileComplete, isFalse);
  });

  test('register sukses -> Authenticated', () async {
    final fake = FakeAuthRepository()
      ..registerResult = const AuthResult(token: 't', role: 'klien')
      ..profile = _profile(complete: false);
    final container = _container(fake);

    await container.read(authStateProvider.notifier).register(
          nama: 'Budi',
          email: 'budi@example.com',
          username: 'budi',
          password: '12345678',
        );

    expect(container.read(authStateProvider), isA<Authenticated>());
  });

  test('logout -> Unauthenticated dan repository.logout dipanggil', () async {
    final fake = FakeAuthRepository()
      ..loginResult = const AuthResult(token: 't', role: 'klien')
      ..profile = _profile(complete: true);
    final container = _container(fake);

    final notifier = container.read(authStateProvider.notifier);
    await notifier.login(emailOrUsername: 'a', password: 'b');
    await notifier.logout();

    expect(container.read(authStateProvider), isA<Unauthenticated>());
    expect(fake.logoutCalled, isTrue);
  });
}
