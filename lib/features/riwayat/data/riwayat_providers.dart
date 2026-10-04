import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import '../../auth/models/progress_cycle.dart';
import '../models/daily_log.dart';
import 'riwayat_repository.dart';

part 'riwayat_providers.g.dart';

@riverpod
RiwayatRepository riwayatRepository(Ref ref) {
  return DioRiwayatRepository(apiClient: ref.watch(apiClientProvider));
}

@riverpod
Future<List<ProgressCycle>> progressCycles(Ref ref) {
  return ref.watch(riwayatRepositoryProvider).getProgressCycles();
}

/// Lazy load per siklus (family) — dipanggil saat card di-expand.
@riverpod
Future<List<DailyLogItem>> cycleLogs(Ref ref, int cycleId) {
  return ref.watch(riwayatRepositoryProvider).getCycleLogs(cycleId);
}
