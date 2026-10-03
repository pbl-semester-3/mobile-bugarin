import 'package:bugarin_mobile/features/auth/data/auth_repository.dart';
import 'package:bugarin_mobile/features/auth/data/auth_repository_provider.dart';
import 'package:bugarin_mobile/features/auth/models/klien_profile.dart';
import 'package:bugarin_mobile/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

KlienProfile _profile({required bool complete, String? role = 'klien'}) =>
    KlienProfile(
      id: 1,
      userId: 10,
      nama: 'Maya',
      role: role,
      profileComplete: complete,
    );

ProviderContainer _container(FakeAuthRepository fake) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  container.listen(authStateProvider, (_, __) {});
  return container;
}

void main() {
  test('state awal AuthUnknown selama restore belum selesai', () {
    final fake = FakeAuthRepository()..tokenToRead = 'token';
    final container = _container(fake);

    expect(container.read(authStateProvider), isA<AuthUnknown>());
  });

  test('token ada + profil lengkap -> Authenticated(profileComplete=true)', () async {
    final fake = FakeAuthRepository()
      ..tokenToRead = 'token'
      ..profile = _profile(complete: true, role: 'klien');
    final container = _container(fake);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).profileComplete, isTrue);
    expect(state.role, 'klien');
    expect(state.profile?.nama, 'Maya');
  });

  test('token ada + profil belum lengkap -> Authenticated(profileComplete=false)',
      () async {
    final fake = FakeAuthRepository()
      ..tokenToRead = 'token'
      ..profile = _profile(complete: false);
    final container = _container(fake);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(authStateProvider);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).profileComplete, isFalse);
  });

  test('token ada tapi getProfile gagal -> Unauthenticated', () async {
    final fake = FakeAuthRepository()
      ..tokenToRead = 'token'
      ..profileError = const AuthException('token invalid');
    final container = _container(fake);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(authStateProvider), isA<Unauthenticated>());
  });

  test('tanpa token -> Unauthenticated', () async {
    final fake = FakeAuthRepository();
    final container = _container(fake);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(authStateProvider), isA<Unauthenticated>());
  });
}
