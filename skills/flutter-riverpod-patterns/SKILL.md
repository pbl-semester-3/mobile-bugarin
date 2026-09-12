---
name: flutter-riverpod-patterns
description: Pola Riverpod (providers, AsyncNotifier, derived provider) untuk state management Mobile Klien Bugarin — dashboard, weekly plan, progress cycle, feedback. Gunakan saat menulis provider baru atau screen yang butuh state.
metadata:
  origin: bugarin-project
  adapted_from: ECC dart-flutter-patterns (MIT license, https://github.com/affaan-m/ECC)
---

# Flutter Riverpod Patterns (Bugarin)

Mobile Klien pakai Riverpod (generator-based, `@riverpod` annotation) untuk seluruh state — dari data server (profil, weekly plan) sampai state UI lokal (form input olahraga sebelum submit). Skill ini fokus ke pola provider yang dipakai berulang di flow Bugarin.

## Activation

- Menulis provider baru untuk resource API (dashboard, PT ku, progres, riwayat, feedback, profil).
- Screen butuh derived/computed state dari beberapa provider (mis. progress bar dari `bb_awal`, `bb_sekarang`, `bb_tujuan`).
- Ada bug: state tidak ter-update setelah mutation (submit log, kirim request PT).

## Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0
dev_dependencies:
  riverpod_generator: ^2.6.0
  build_runner: ^2.4.0
```

Jalankan `dart run build_runner watch -d` selama development supaya file `*.g.dart` ter-generate otomatis tiap provider baru ditulis.

## Pola 1: Provider Data Server (read)

```dart
// providers/dashboard_provider.dart
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/klien/dashboard-summary');
  return DashboardSummary.fromJson(response.data['data']);
}
```

Widget cukup `ref.watch(dashboardSummaryProvider)` dan pattern-match `AsyncValue`:

```dart
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return summary.when(
      data: (data) => _DashboardContent(data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorRetryView(
        message: 'Gagal memuat dashboard',
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
      ),
    );
  }
}
```

## Pola 2: Notifier untuk Mutasi (submit log, kirim request PT)

```dart
// providers/activity_log_provider.dart
@riverpod
class ActivityLogSubmit extends _$ActivityLogSubmit {
  @override
  FutureOr<void> build() {} // state awal kosong

  Future<void> submit({
    required int olahragaId,
    required int durasiMenit,
    double? jarakMeter,
  }) async {
    state = const AsyncLoading();
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() async {
      await api.post('/klien/activity-logs', data: {
        'olahragaId': olahragaId,
        'durasiMenit': durasiMenit,
        if (jarakMeter != null) 'jarakMeter': jarakMeter,
      });
      // Invalidate provider yang datanya ikut berubah setelah submit:
      ref.invalidate(dashboardSummaryProvider); // streak & kalori berubah
      ref.invalidate(progressCyclesProvider);   // riwayat harian berubah
    });
  }
}
```

Widget submit tombol:
```dart
ElevatedButton(
  onPressed: ref.watch(activityLogSubmitProvider).isLoading
      ? null
      : () => ref.read(activityLogSubmitProvider.notifier).submit(
            olahragaId: selectedOlahragaId,
            durasiMenit: durasi,
            jarakMeter: butuhJarak ? jarak : null,
          ),
  child: const Text('Simpan'),
)
```

**Aturan invalidation sama seperti di `tanstack-query-patterns` (Frontend)**: pikirkan semua provider lain yang datanya ikut berubah, jangan cuma invalidate yang paling jelas.

## Pola 3: Derived Provider (progress bar BB)

```dart
// providers/progress_bar_provider.dart
@riverpod
double progressBarPercent(Ref ref) {
  final cycle = ref.watch(activeCycleProvider).valueOrNull;
  final currentWeight = ref.watch(latestWeightLogProvider).valueOrNull;
  if (cycle == null || currentWeight == null) return 0;

  final total = (cycle.bbTujuanKg - cycle.bbAwalKg).abs();
  if (total == 0) return 100;
  final progressed = (currentWeight.beratBadanKg - cycle.bbAwalKg).abs();

  // Clamp — BB sekarang bisa melewati target (lihat catatan di PRD Mobile bab 6)
  return (progressed / total * 100).clamp(0, 100);
}
```

## Pola 4: Family Provider (parameterized — mis. detail per cycle di Riwayat)

```dart
@riverpod
Future<List<DailyLog>> cycleLogs(Ref ref, int cycleId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/klien/progress-cycles/$cycleId/logs');
  return (response.data['data'] as List).map(DailyLog.fromJson).toList();
}
```

Dipanggil lazy saat card di-expand: `ref.watch(cycleLogsProvider(cycle.id))` — **jangan** fetch semua cycle logs di awal load Riwayat (sesuai catatan lazy-load di `Bugarin_PRD_Mobile.md`).

## State Class: Sealed, Bukan Bang Operator

```dart
sealed class PairingStatus {}
final class NoPt extends PairingStatus {}
final class PendingRequest extends PairingStatus { final String ptNama; const PendingRequest(this.ptNama); }
final class HasPt extends PairingStatus { final PtInfo pt; const HasPt(this.pt); }
final class Rejected extends PairingStatus { final String alasan; const Rejected(this.alasan); }

// Exhaustive switch di UI — compiler paksa handle semua kondisi (termasuk state kosong PT ku)
Widget buildPtSection(PairingStatus status) => switch (status) {
  NoPt() => const RekomendasiPtList(),
  PendingRequest(:final ptNama) => MenungguKonfirmasi(ptNama: ptNama),
  HasPt(:final pt) => PtAktifCard(pt: pt),
  Rejected(:final alasan) => DitolakView(alasan: alasan),
};
```

## Anti-Patterns

| Anti-Pattern | Risiko | Perbaikan |
|---|---|---|
| `ref.watch()` untuk trigger aksi (bukan `ref.read()`) di dalam callback/`onPressed` | Widget rebuild tidak perlu, kadang bug subtle | `ref.watch()` cuma di `build()`, `ref.read()` di event handler |
| Fetch semua data (termasuk semua cycle logs) sekaligus di provider utama | Boros bandwidth/memori, lambat di load awal | Family provider + lazy load per interaksi (Pola 4) |
| Tidak invalidate provider terkait setelah mutation | UI nampilin data basi (streak/kalori tidak update) | Invalidate semua provider yang datanya ikut berubah |
| Pakai `!` untuk unwrap `AsyncValue`/nullable tanpa guard | Crash runtime | `.valueOrNull`, `AsyncValue.when()`, atau pattern matching |

## Related

- Skill: `dio-jwt-networking` — `apiClientProvider` yang dipakai di semua contoh di atas
- Skill: `gorouter-navigation-bugarin` — auth guard yang bergantung ke provider profil/status
- Dokumen: `Bugarin_PRD_Mobile.md` — daftar lengkap provider yang dibutuhkan per screen
