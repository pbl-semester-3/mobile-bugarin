import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'pt_repository.dart';

part 'pt_repository_provider.g.dart';

@riverpod
PtRepository ptRepository(Ref ref) {
  return DioPtRepository(apiClient: ref.watch(apiClientProvider));
}
