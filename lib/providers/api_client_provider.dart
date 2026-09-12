import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'auth_provider.dart';

part 'api_client_provider.g.dart';

@riverpod
TokenStorage tokenStorage(Ref ref) => TokenStorage();

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(authStateNotifierProvider.notifier).logout(),
  );
}
