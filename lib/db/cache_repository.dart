import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../features/dashboard/models/dashboard_summary.dart';
import '../features/progres/models/master_data.dart';
import '../features/progres/models/weekly_plan.dart';
import 'local_database.dart';

/// Kontrak cache lokal (drift). Dibuat interface supaya orkestrasi
/// (kapan tulis/baca cache) bisa di-unit-test dengan fake tanpa SQLite native.
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

class DriftCacheRepository implements CacheRepository {
  final LocalDatabase db;

  DriftCacheRepository(this.db);

  @override
  Future<void> cacheMasterOlahraga(List<MasterOlahraga> list) async {
    await db.transaction(() async {
      await db.delete(db.masterOlahragaCache).go();
      await db.batch(
        (batch) => batch.insertAll(
          db.masterOlahragaCache,
          list.map((o) => MasterOlahragaCacheCompanion.insert(
                id: Value(o.id),
                nama: o.nama,
                metValue: o.metValue,
                butuhJarak: o.butuhJarak,
              )),
        ),
      );
    });
  }

  @override
  Future<List<MasterOlahraga>> getCachedMasterOlahraga() async {
    final rows = await db.select(db.masterOlahragaCache).get();
    return rows
        .map((r) => MasterOlahraga(
              id: r.id,
              nama: r.nama,
              metValue: r.metValue,
              kategori: '',
              butuhJarak: r.butuhJarak,
            ))
        .toList();
  }

  @override
  Future<void> cacheMasterMakanan(List<MasterMakanan> list) async {
    await db.transaction(() async {
      await db.delete(db.masterMakananCache).go();
      await db.batch(
        (batch) => batch.insertAll(
          db.masterMakananCache,
          list.map((m) => MasterMakananCacheCompanion.insert(
                id: Value(m.id),
                nama: m.nama,
                kaloriPer100g: m.kaloriPer100g,
              )),
        ),
      );
    });
  }

  @override
  Future<List<MasterMakanan>> getCachedMasterMakanan({String? q}) async {
    final rows = await db.select(db.masterMakananCache).get();
    final query = (q ?? '').toLowerCase();
    return rows
        .where((r) => query.isEmpty || r.nama.toLowerCase().contains(query))
        .map((r) => MasterMakanan(
              id: r.id,
              nama: r.nama,
              kaloriPer100g: r.kaloriPer100g,
              kategori: '',
              sumber: 'seed',
            ))
        .toList();
  }

  @override
  Future<void> cacheWeeklyPlan(WeeklyPlan plan) async {
    await db.into(db.weeklyPlanCache).insertOnConflictUpdate(
          WeeklyPlanCacheCompanion.insert(
            id: Value(plan.id),
            workoutPlanJson: jsonEncode(plan.workoutPlan.map((e) => e.toJson()).toList()),
            mealPlanJson: jsonEncode(plan.mealPlan.map((e) => e.toJson()).toList()),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<WeeklyPlan?> getCachedWeeklyPlan() async {
    final row = await (db.select(db.weeklyPlanCache)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    return WeeklyPlan.fromJson({
      'id': row.id,
      'mingguMulai': '',
      'status': '',
      'workoutPlan': jsonDecode(row.workoutPlanJson),
      'mealPlan': jsonDecode(row.mealPlanJson),
    });
  }

  @override
  Future<void> cacheDashboardSummary(DashboardSummary summary) async {
    await db.into(db.dashboardSummaryCache).insertOnConflictUpdate(
          DashboardSummaryCacheCompanion.insert(
            id: const Value(1),
            json: jsonEncode(summary.toJson()),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<DashboardSummary?> getCachedDashboardSummary() async {
    final row = await (db.select(db.dashboardSummaryCache)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    return DashboardSummary.fromJson(jsonDecode(row.json) as Map<String, dynamic>);
  }
}
