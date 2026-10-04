import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/theme_provider.dart';
import '../../db/cache_provider.dart';
import '../../db/cache_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/bugarin_header.dart';
import 'data/dashboard_repository.dart';
import 'data/dashboard_repository_provider.dart';
import 'models/dashboard_summary.dart';

part 'dashboard_screen.g.dart';

/// Stale-while-revalidate: tampilkan cache dulu (bila ada), lalu fetch fresh
/// dan simpan ke cache. Bila fetch gagal tetapi cache ada, tetap pakai cache.
Stream<DashboardSummary> dashboardSummaryStream({
  required DashboardRepository repo,
  required CacheRepository cache,
}) async* {
  DashboardSummary? cached;
  try {
    cached = await cache.getCachedDashboardSummary();
  } catch (_) {
    // Cache gagal dibaca — lanjut ke fetch.
  }
  if (cached != null) yield cached;

  try {
    final fresh = await repo.getSummary();
    await cache.cacheDashboardSummary(fresh);
    yield fresh;
  } catch (e) {
    if (cached == null) rethrow;
  }
}

@riverpod
Stream<DashboardSummary> dashboardSummary(Ref ref) {
  return dashboardSummaryStream(
    repo: ref.watch(dashboardRepositoryProvider),
    cache: ref.watch(cacheRepositoryProvider),
  );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatKcal(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final auth = ref.watch(authStateProvider);

    String userName = 'Sobat Bugarin';
    int? cycleDay;
    if (auth is Authenticated) {
      userName = auth.profile?.nama ?? userName;
      final cycle = auth.profile?.activeCycle;
      final start = cycle == null ? null : DateTime.tryParse(cycle.tanggalMulai);
      if (start != null) {
        cycleDay = DateTime.now().difference(start).inDays + 1;
      }
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5520), strokeWidth: 2.2),
          ),
          error: (err, _) => _ErrorState(
            message: err is Exception ? '$err' : 'Gagal memuat dashboard.',
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
          data: (data) => RefreshIndicator(
            color: const Color(0xFFFF5520),
            onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BugarinHeader(subtitle: 'Beranda'),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat Datang, $userName',
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cycleDay != null
                        ? 'Hari ke-$cycleDay Siklus Transformasi'
                        : 'Semangat menjalani harimu!',
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  if (data.isReminderActive) ...[
                    _buildReminderBanner(),
                    const SizedBox(height: 16),
                  ],

                  _buildKaloriCard(data),
                  const SizedBox(height: 26),

                  _buildJadwalSection(data),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5520).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF5520).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFFF5520), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Durasi targetmu sudah lewat. Catat berat badan terbaru atau mulai target baru di Profil.',
                style: TextStyle(color: context.textPrimary, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu kalori: TARGET-ONLY (backend belum kirim kalori masuk hari ini).
  Widget _buildKaloriCard(DashboardSummary data) {
    final target = data.targetKaloriHariIni;

    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: context.border, width: 1.2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(210, 210),
                    painter: LiveArcPainter(
                      progress: 1.0, // ring dekoratif (target-only)
                      strokeWidth: 14.0,
                      trackColor: context.isDark ? const Color(0xFF162520) : const Color(0xFFE2E8E5),
                      activeColor: const Color(0xFFFF5520),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        target == null ? '--' : _formatKcal(target),
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'KKAL / HARI',
                        style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        target == null ? 'Belum ada target aktif' : 'Target kalori harian',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.isDark ? const Color(0xFF1A2E27) : const Color(0xFFFFECE5),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF5520), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${data.streak} Hari',
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Text('Beruntun', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Ritme Konsisten',
                          style: TextStyle(color: context.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalSection(DashboardSummary data) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jadwal Sesi Minggu Ini',
                  style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          if (data.pt == null)
            _buildNoPtCard()
          else ...[
            _buildPtCard(data.pt!),
            const SizedBox(height: 12),
            if (data.jadwalMingguan.isEmpty)
              _buildEmptyJadwal()
            else
              ...data.jadwalMingguan.map((item) => _buildJadwalItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildNoPtCard() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.border, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceInner,
                border: Border.all(color: const Color(0xFFFF5520), width: 1.8),
              ),
              child: const Icon(Icons.sports, color: Color(0xFFFF5520), size: 26),
            ),
            const SizedBox(height: 14),
            Text('Belum punya Personal Trainer',
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'Pilih PT di tab "PT ku" untuk mendapatkan jadwal latihan dan panduan program.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPtCard(PtSummary pt) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceInner,
                border: Border.all(color: const Color(0xFFFF5520), width: 1.8),
              ),
              child: Center(
                child: Text(
                  pt.nama.trim().isEmpty ? '?' : pt.nama.trim()[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFFFF5520), fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coach ${pt.nama}',
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    pt.spesialisasi == 'naik_bb'
                        ? 'Naik BB / Massa Otot'
                        : pt.spesialisasi == 'turun_bb'
                            ? 'Turun BB / Defisit Kalori'
                            : 'Personal Trainer',
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyJadwal() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: context.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada jadwal disetujui PT untuk minggu ini.',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalItem(WorkoutPlanItem item) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.border),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF5520), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.jenis,
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFFF5520)),
                      const SizedBox(width: 4),
                      Text('${item.hari}, ${item.jam}',
                          style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                  if (item.lokasi.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFFF5520)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(item.lokasi,
                              style: TextStyle(color: context.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5520),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER UNTUK RING KALORI
// ============================================================================
class LiveArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color activeColor;

  LiveArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = 145 * (math.pi / 180);
    const totalSweep = 250 * (math.pi / 180);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    if (progress > 0.001) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        totalSweep * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LiveArcPainter oldDelegate) => true;
}
