import '../features/dashboard/models/dashboard_summary.dart';
import '../features/progres/models/master_data.dart';
import '../features/progres/models/weekly_plan.dart';
import 'cache_repository.dart';

/// Cache no-op untuk platform tanpa SQLite native (web). Semua operasi baca
/// mengembalikan kosong dan tulis diabaikan → app tetap jalan, hanya tanpa
/// offline cache. Lihat `cache_backend_*`.
class NoopCacheRepository implements CacheRepository {
  @override
  Future<void> cacheMasterOlahraga(List<MasterOlahraga> list) async {}

  @override
  Future<List<MasterOlahraga>> getCachedMasterOlahraga() async => const [];

  @override
  Future<void> cacheMasterMakanan(List<MasterMakanan> list) async {}

  @override
  Future<List<MasterMakanan>> getCachedMasterMakanan({String? q}) async => const [];

  @override
  Future<void> cacheWeeklyPlan(WeeklyPlan plan) async {}

  @override
  Future<WeeklyPlan?> getCachedWeeklyPlan() async => null;

  @override
  Future<void> cacheDashboardSummary(DashboardSummary summary) async {}

  @override
  Future<DashboardSummary?> getCachedDashboardSummary() async => null;
}
