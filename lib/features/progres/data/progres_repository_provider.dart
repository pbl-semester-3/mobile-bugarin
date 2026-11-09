import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'progres_repository.dart';

part 'progres_repository_provider.g.dart';

@riverpod
ProgresRepository progresRepository(Ref ref) {
  return DioProgresRepository(apiClient: ref.watch(apiClientProvider));
}
