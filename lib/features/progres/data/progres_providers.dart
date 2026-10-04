import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../db/cache_provider.dart';
import '../../../db/cache_repository.dart';
import '../models/master_data.dart';
import '../models/weekly_plan.dart';
import 'master_repository.dart';
import 'master_repository_provider.dart';
import 'progres_repository.dart';
import 'progres_repository_provider.dart';

part 'progres_providers.g.dart';

class MasterData {
  final List<MasterOlahraga> olahraga;
  final List<MasterMakanan> makanan;
  final bool fromCache;

  const MasterData({
    required this.olahraga,
    required this.makanan,
    this.fromCache = false,
  });
}

/// Orkestrasi master data: fetch API lalu simpan ke cache. Bila network gagal,
/// fallback ke cache lokal; bila cache juga kosong, error dilempar.
///
/// Fungsi murni agar bisa di-unit-test tanpa SQLite/Riverpod.
Future<MasterData> loadMasterData({
  required MasterRepository master,
  required CacheRepository cache,
}) async {
  try {
    final olahraga = await master.getOlahraga();
    final makanan = await master.getMakanan();
    await cache.cacheMasterOlahraga(olahraga);
    await cache.cacheMasterMakanan(makanan);
    return MasterData(olahraga: olahraga, makanan: makanan);
  } catch (_) {
    final olahraga = await cache.getCachedMasterOlahraga();
    final makanan = await cache.getCachedMasterMakanan();
    if (olahraga.isEmpty && makanan.isEmpty) rethrow;
    return MasterData(olahraga: olahraga, makanan: makanan, fromCache: true);
  }
}

@riverpod
Future<MasterData> masterData(Ref ref) {
  return loadMasterData(
    master: ref.watch(masterRepositoryProvider),
    cache: ref.watch(cacheRepositoryProvider),
  );
}

/// Orkestrasi weekly plan: fetch API lalu simpan ke cache; bila gagal,
/// fallback ke cache (bisa `null` bila belum pernah ter-cache).
Future<WeeklyPlan?> loadWeeklyPlan({
  required ProgresRepository repo,
  required CacheRepository cache,
}) async {
  try {
    final plan = await repo.getCurrentWeeklyPlan();
    if (plan != null) await cache.cacheWeeklyPlan(plan);
    return plan;
  } catch (_) {
    return cache.getCachedWeeklyPlan();
  }
}

@riverpod
Future<WeeklyPlan?> weeklyPlan(Ref ref) {
  return loadWeeklyPlan(
    repo: ref.watch(progresRepositoryProvider),
    cache: ref.watch(cacheRepositoryProvider),
  );
}
