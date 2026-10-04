import 'package:bugarin_mobile/features/progres/data/progres_providers.dart';
import 'package:bugarin_mobile/features/progres/models/weekly_plan.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _plan = WeeklyPlan(
  id: 5,
  mingguMulai: '2026-09-29',
  status: 'disetujui',
  workoutPlan: [
    WorkoutPlanItem(hari: 'Senin', jam: '16:30', jenis: 'Upper Body', lokasi: 'FitZone'),
  ],
  mealPlan: [
    MealPlanItem(waktu: 'Siang', menu: 'Nasi + Ayam', estimasiKalori: 600),
  ],
);

void main() {
  test('sukses API -> plan dikembalikan & ditulis ke cache', () async {
    final repo = FakeProgresRepository()..currentPlan = _plan;
    final cache = FakeCacheRepository();

    final plan = await loadWeeklyPlan(repo: repo, cache: cache);

    expect(plan?.id, 5);
    expect(cache.weeklyPlanWritten, isTrue);
    expect(cache.cachedWeeklyPlan?.workoutPlan.single.jenis, 'Upper Body');
  });

  test('API gagal -> fallback cache', () async {
    final repo = FakeProgresRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository()..cachedWeeklyPlan = _plan;

    final plan = await loadWeeklyPlan(repo: repo, cache: cache);

    expect(plan?.id, 5);
    expect(cache.weeklyPlanWritten, isFalse);
  });

  test('API gagal & cache kosong -> null', () async {
    final repo = FakeProgresRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository();

    expect(await loadWeeklyPlan(repo: repo, cache: cache), isNull);
  });

  test('API null (belum ada plan) -> null, tidak menulis cache', () async {
    final repo = FakeProgresRepository()..currentPlan = null;
    final cache = FakeCacheRepository();

    final plan = await loadWeeklyPlan(repo: repo, cache: cache);

    expect(plan, isNull);
    expect(cache.weeklyPlanWritten, isFalse);
  });
}
