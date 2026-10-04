import 'package:bugarin_mobile/features/dashboard/dashboard_screen.dart';
import 'package:bugarin_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:bugarin_mobile/features/dashboard/models/dashboard_summary.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../progres/fakes.dart';

const _cached = DashboardSummary(
  pt: null,
  targetKaloriHariIni: 1000,
  streak: 1,
  jadwalMingguan: [],
  isReminderActive: false,
  unreadFeedbackCount: 0,
);
const _fresh = DashboardSummary(
  pt: null,
  targetKaloriHariIni: 2000,
  streak: 2,
  jadwalMingguan: [],
  isReminderActive: false,
  unreadFeedbackCount: 3,
);

class FakeDashboardRepository implements DashboardRepository {
  DashboardSummary summary = _fresh;
  ApiException? error;
  int calls = 0;

  @override
  Future<DashboardSummary> getSummary() async {
    calls++;
    if (error != null) throw error!;
    return summary;
  }
}

void main() {
  test('cache ada -> emit cache dulu lalu fresh, cache diperbarui', () async {
    final repo = FakeDashboardRepository()..summary = _fresh;
    final cache = FakeCacheRepository()..cachedDashboard = _cached;

    final emitted = await dashboardSummaryStream(repo: repo, cache: cache).toList();

    expect(emitted.length, 2);
    expect(emitted[0].targetKaloriHariIni, 1000); // cache dulu
    expect(emitted[1].targetKaloriHariIni, 2000); // fresh
    expect(cache.cachedDashboard?.targetKaloriHariIni, 2000);
    expect(cache.dashboardWritten, isTrue);
  });

  test('cache kosong -> emit fresh saja', () async {
    final repo = FakeDashboardRepository()..summary = _fresh;
    final cache = FakeCacheRepository();

    final emitted = await dashboardSummaryStream(repo: repo, cache: cache).toList();

    expect(emitted.length, 1);
    expect(emitted.single.targetKaloriHariIni, 2000);
  });

  test('cache ada + API gagal -> emit cache, tidak error', () async {
    final repo = FakeDashboardRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository()..cachedDashboard = _cached;

    final emitted = await dashboardSummaryStream(repo: repo, cache: cache).toList();

    expect(emitted.length, 1);
    expect(emitted.single.targetKaloriHariIni, 1000);
  });

  test('cache kosong + API gagal -> error', () async {
    final repo = FakeDashboardRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository();

    expect(
      () => dashboardSummaryStream(repo: repo, cache: cache).toList(),
      throwsA(isA<ApiException>()),
    );
  });
}
