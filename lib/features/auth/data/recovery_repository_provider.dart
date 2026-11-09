import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'recovery_repository.dart';

part 'recovery_repository_provider.g.dart';

@riverpod
RecoveryRepository recoveryRepository(Ref ref) {
  return DioRecoveryRepository(apiClient: ref.watch(apiClientProvider));
}
