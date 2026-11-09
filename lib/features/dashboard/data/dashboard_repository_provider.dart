import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import 'dashboard_repository.dart';

part 'dashboard_repository_provider.g.dart';

@riverpod
DashboardRepository dashboardRepository(Ref ref) {
  return DioDashboardRepository(apiClient: ref.watch(apiClientProvider));
}
