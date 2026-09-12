import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/api_client_provider.dart';
import '../../services/api_client.dart';

part 'dashboard_screen.g.dart';

class DashboardSummary {
  final int targetKaloriHariIni;
  final int streakHari;
  DashboardSummary({required this.targetKaloriHariIni, required this.streakHari});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        targetKaloriHariIni: json['targetKaloriHariIni'] ?? 0,
        streakHari: json['streakHari'] ?? 0,
      );
}

// TODO: implementasikan sesuai Bugarin_PRD_Mobile.md bab 3.3 (Card PT aktif, badge kalori,
// badge streak, jadwal latihan + lokasi, banner reminder durasi lewat).
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.dio.get('/klien/dashboard-summary');
  return response.unwrap(DashboardSummary.fromJson);
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return summary.when(
      data: (data) => Center(child: Text('Streak: ${data.streakHari} hari')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(dashboardSummaryProvider),
          child: const Text('Gagal memuat, coba lagi'),
        ),
      ),
    );
  }
}
