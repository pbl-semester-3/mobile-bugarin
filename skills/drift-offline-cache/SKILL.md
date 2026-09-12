---
name: drift-offline-cache
description: Pola cache lokal SQLite (drift) untuk master data dan weekly plan Mobile Klien Bugarin, sesuai strategi offline resilience di PRD Mobile. Gunakan saat implementasi local cache atau sinkronisasi data offline.
metadata:
  origin: bugarin-project
---

# Drift Offline Cache (Bugarin Mobile)

Rujuk `Bugarin_PRD_Mobile.md` bab 5 untuk kandidat data yang di-cache. Prinsip: **cache untuk data baca (read), bukan untuk antrian submit offline** — submit log (activity/meal/weight) cukup gagal-dan-retry manual kalau tidak ada koneksi, sesuai keputusan scope MVP (sync-queue offline-first di luar scope PBL).

## Activation

- Implementasi cache lokal untuk `master_olahraga`/`master_makanan` (dropdown/search tanpa network tiap kali).
- Cache weekly plan minggu berjalan supaya tab Progres tetap bisa dibuka offline.
- Ada kebutuhan stale-while-revalidate untuk dashboard summary.

## Setup

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
dev_dependencies:
  drift_dev: ^2.21.0
  build_runner: ^2.4.0
```

## Schema Drift (mirror ringkas dari master data backend)

```dart
// db/local_database.dart
import 'package:drift/drift.dart';

part 'local_database.g.dart';

class MasterOlahragaCache extends Table {
  IntColumn get id => integer()();
  TextColumn get nama => text()();
  RealColumn get metValue => real().named('met_value')();
  BoolColumn get butuhJarak => boolean().named('butuh_jarak')();

  @override
  Set<Column> get primaryKey => {id};
}

class MasterMakananCache extends Table {
  IntColumn get id => integer()();
  TextColumn get nama => text()();
  RealColumn get kaloriPer100g => real().named('kalori_per_100g')();

  @override
  Set<Column> get primaryKey => {id};
}

class WeeklyPlanCache extends Table {
  IntColumn get id => integer()();
  TextColumn get workoutPlanJson => text().named('workout_plan_json')(); // simpan raw JSON string
  TextColumn get mealPlanJson => text().named('meal_plan_json')();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [MasterOlahragaCache, MasterMakananCache, WeeklyPlanCache])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

## Pola Sync Penuh untuk Master Data (jarang berubah)

Master data cukup "sync penuh" (hapus semua, insert ulang) tiap app dibuka atau di-refresh manual — datanya kecil dan jarang berubah, tidak perlu diff-based sync yang rumit:

```dart
// repositories/master_data_repository.dart
class MasterDataRepository {
  final LocalDatabase db;
  final ApiClient api;

  Future<void> syncOlahraga() async {
    final response = await api.dio.get('/master/olahraga');
    final items = (response.data['data'] as List).map((e) => MasterOlahragaCacheCompanion.insert(
          id: e['id'],
          nama: e['nama'],
          metValue: e['metValue'],
          butuhJarak: e['butuhJarak'],
        ));

    await db.transaction(() async {
      await db.delete(db.masterOlahragaCache).go();
      await db.batch((batch) => batch.insertAll(db.masterOlahragaCache, items));
    });
  }

  // Dropdown baca dari cache lokal, bukan network setiap kali buka form:
  Future<List<MasterOlahragaCacheData>> getOlahragaList() => db.select(db.masterOlahragaCache).get();
}
```

Panggil `syncOlahraga()`/`syncMakanan()` saat app startup (`main()` setelah login berhasil) dan sediakan tombol manual refresh di UI kalau ada kebutuhan (mis. admin menambah jenis olahraga baru di tengah minggu — jarang terjadi, tapi opsi refresh tetap perlu ada).

## Pola Cache Weekly Plan (untuk baca offline)

```dart
Future<void> cacheWeeklyPlan(WeeklyPlan plan) async {
  await db.into(db.weeklyPlanCache).insertOnConflictUpdate(
    WeeklyPlanCacheCompanion.insert(
      id: plan.id,
      workoutPlanJson: jsonEncode(plan.workoutPlan),
      mealPlanJson: jsonEncode(plan.mealPlan),
      cachedAt: DateTime.now(),
    ),
  );
}

// Dipanggil setelah fetch sukses dari network:
final plan = await api.getCurrentWeeklyPlan();
await cacheWeeklyPlan(plan);

// Dibaca sebagai fallback kalau network gagal:
Future<WeeklyPlan?> getCachedWeeklyPlan() async {
  final row = await (db.select(db.weeklyPlanCache)..limit(1)).getSingleOrNull();
  if (row == null) return null;
  return WeeklyPlan(
    id: row.id,
    workoutPlan: List<WorkoutItem>.from(jsonDecode(row.workoutPlanJson)),
    mealPlan: List<MealItem>.from(jsonDecode(row.mealPlanJson)),
  );
}
```

## Pola Stale-While-Revalidate (Dashboard Summary)

```dart
@riverpod
Stream<DashboardSummary> dashboardSummaryWithCache(Ref ref) async* {
  final cached = await ref.watch(cacheRepositoryProvider).getCachedDashboard();
  if (cached != null) yield cached; // tampilkan versi lama dulu, jangan blank screen

  final fresh = await ref.watch(apiClientProvider).getDashboardSummary();
  await ref.watch(cacheRepositoryProvider).cacheDashboard(fresh);
  yield fresh; // ganti dengan data terbaru setelah network selesai
}
```

## Anti-Patterns

| Anti-Pattern | Risiko | Perbaikan |
|---|---|---|
| Bangun sync-queue offline untuk `activity_logs`/`meal_logs` | Kompleksitas tinggi (conflict resolution, retry logic) di luar scope timeline PBL | Cukup tampilkan error + tombol retry manual saat submit gagal karena offline |
| Diff-based sync untuk master data yang kecil & jarang berubah | Overengineering untuk kasus yang cukup "hapus-insert-ulang" | Full sync (delete all + insert all) tiap refresh |
| Simpan JSON weekly plan sebagai kolom terstruktur drift (banyak kolom nested) | Skema lokal jadi rumit mengikuti perubahan struktur AI generatif | Simpan sebagai `text()` JSON string, decode di layer repository (sama fleksibelnya dengan kolom JSON di MySQL backend) |
| Tidak ada fallback UI saat cache kosong DAN network gagal | User lihat layar kosong tanpa penjelasan | Tampilkan empty state + pesan "belum ada data tersimpan, coba refresh" |

## Related

- Skill: `flutter-riverpod-patterns` — provider yang mengorkestrasi cache + network (Pola Stale-While-Revalidate)
- Skill: `dio-jwt-networking` — sumber data network yang di-cache
- Dokumen: `Bugarin_PRD_Mobile.md` bab 5 — daftar kandidat data cache resmi
