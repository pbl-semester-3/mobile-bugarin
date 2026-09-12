import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  TextColumn get workoutPlanJson => text().named('workout_plan_json')();
  TextColumn get mealPlanJson => text().named('meal_plan_json')();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// TODO: lengkapi query get-or-sync sesuai skill drift-offline-cache
// (syncOlahraga, syncMakanan, cacheWeeklyPlan, getCachedWeeklyPlan).
@DriftDatabase(tables: [MasterOlahragaCache, MasterMakananCache, WeeklyPlanCache])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bugarin_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
