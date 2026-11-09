import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'auth_repository.dart';

part 'auth_repository_provider.g.dart';

/// Repository auth tunggal yang dipakai `AuthStateNotifier`.
///
/// Mengembalikan interface [AuthRepository] supaya gampang di-override
/// dengan fake di unit test.
@riverpod
AuthRepository authRepository(Ref ref) {
  return DioAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}
