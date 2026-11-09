import '../features/dashboard/models/dashboard_summary.dart';
import '../features/progres/models/master_data.dart';
import '../features/progres/models/weekly_plan.dart';

/// Kontrak cache lokal. Dibuat interface supaya:
/// - orkestrasi (kapan tulis/baca cache) bisa di-unit-test dengan fake, dan
/// - implementasi drift (native/ffi) bisa di-bypass di web (lihat `cache_backend_*`).
abstract interface class CacheRepository {
  Future<void> cacheMasterOlahraga(List<MasterOlahraga> list);
  Future<List<MasterOlahraga>> getCachedMasterOlahraga();

  Future<void> cacheMasterMakanan(List<MasterMakanan> list);
  Future<List<MasterMakanan>> getCachedMasterMakanan({String? q});

  Future<void> cacheWeeklyPlan(WeeklyPlan plan);
  Future<WeeklyPlan?> getCachedWeeklyPlan();

  Future<void> cacheDashboardSummary(DashboardSummary summary);
  Future<DashboardSummary?> getCachedDashboardSummary();
}
