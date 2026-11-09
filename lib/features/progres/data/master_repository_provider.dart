import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'master_repository.dart';

part 'master_repository_provider.g.dart';

@riverpod
MasterRepository masterRepository(Ref ref) {
  return DioMasterRepository(apiClient: ref.watch(apiClientProvider));
}
