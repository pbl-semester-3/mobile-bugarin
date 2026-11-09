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
      role: 'klien',
      profileComplete: complete,
    );

void main() {
  test('refreshProfile memperbarui profileComplete ke true', () async {
    final fake = FakeAuthRepository()..profile = _profile(complete: true);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    container.listen(authStateProvider, (_, __) {});

    await Future<void>.delayed(Duration.zero); // settle restore (tanpa token)

    final profile =
        await container.read(authStateProvider.notifier).refreshProfile();
    final state = container.read(authStateProvider);

    expect(profile?.profileComplete, isTrue);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).profileComplete, isTrue);
    expect(state.profile?.nama, 'Maya');
  });

  test('refreshProfile gagal -> state tidak berubah, return null', () async {
    final fake = FakeAuthRepository()
      ..profileError = const AuthException('offline');
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    container.listen(authStateProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);

    final before = container.read(authStateProvider);
    final profile =
        await container.read(authStateProvider.notifier).refreshProfile();

    expect(profile, isNull);
    expect(container.read(authStateProvider), before);
  });
}
