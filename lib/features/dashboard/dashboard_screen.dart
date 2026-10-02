import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

part 'dashboard_screen.g.dart';

// ============================================================================
// 1. DATA MODEL & PROVIDER
// ============================================================================
class DashboardSummary {
  final String userName;
  final int cycleDay;
  final int targetCalories;
  final int consumedCalories;
  final int streakDays;

  const DashboardSummary({
    required this.userName,
    required this.cycleDay,
    required this.targetCalories,
    required this.consumedCalories,
    required this.streakDays,
  });
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  const storage = FlutterSecureStorage();
  final savedTarget = await storage.read(key: 'daily_calorie_target');
  final savedName = await storage.read(key: 'user_name');

  return DashboardSummary(
    userName: (savedName != null && savedName.isNotEmpty) ? savedName : 'Maya',
    cycleDay: 14,
    targetCalories: savedTarget != null ? (int.tryParse(savedTarget) ?? 2175) : 2175,
    consumedCalories: 1420,
    streakDays: 12,
  );
}

// ============================================================================
// 2. MAIN SCREEN WIDGET
// ============================================================================
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Dipercepat dari 4000ms agar lebih responsif
    );
    
    _curvedAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerReplay() {
    _animController.forward(from: 0.0);
  }

  String _formatKcal(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan state untuk memicu animasi saat data selesai di-load
    ref.listen<AsyncValue<DashboardSummary>>(
      dashboardSummaryProvider,
      (previous, next) {
        if (next.hasValue && (previous == null || previous.isLoading)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animController.forward(from: 0.0);
          });
        }
      },
    );

    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5520), strokeWidth: 2.2),
          ),
          error: (err, _) => Center(
            child: Text('Gagal memuat: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (data) {
            final double targetProgress = (data.consumedCalories / (data.targetCalories == 0 ? 1 : data.targetCalories)).clamp(0.0, 1.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BugarinHeader(subtitle: 'Beranda'),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Selamat Datang, ${data.userName}',
                    style: TextStyle(color: context.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hari ke-${data.cycleDay} Siklus Transformasi',
                    style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: _triggerReplay,
                    child: Container(
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
                            child: AnimatedBuilder(
                              animation: _curvedAnimation,
                              builder: (context, _) {
                                final animVal = _curvedAnimation.value;
                                final animatedConsumed = (data.consumedCalories * animVal).round();
                                final animatedRemaining = (data.targetCalories - animatedConsumed).clamp(0, data.targetCalories);

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(210, 210),
                                      painter: LiveArcPainter(
                                        progress: targetProgress * animVal,
                                        strokeWidth: 14.0,
                                        trackColor: context.isDark ? const Color(0xFF162520) : const Color(0xFFE2E8E5),
                                        activeColor: const Color(0xFFFF5520),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatKcal(animatedConsumed),
                                          style: TextStyle(color: context.textPrimary, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'DARI ${_formatKcal(data.targetCalories)} KKAL',
                                          style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tersisa $animatedRemaining kkal',
                                          style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
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
                                  child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5520), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('${data.streakDays} Hari', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 5),
                                        Text('Beruntun', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Ritme Konsisten', style: TextStyle(color: context.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 26),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jadwal Sesi Hari Ini', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Lihat Kalender', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFF5520), width: 1.8),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1594381898411-846e7d193883?w=200'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Coach Sarah Jenkins', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 3),
                                  Text('Calisthenics & Hypertrophy Lead', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFFF5520)),
                                      const SizedBox(width: 5),
                                      Text('Hari ini, 16:30 - 17:30 WIB', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFFFF5520)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'FitZone Studio B, Senopati',
                                          style: TextStyle(color: context.textSecondary, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5520),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Masuk Sesi Latihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: context.surfaceInner,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.border),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF5520), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 3. CUSTOM PAINTER UNTUK GRAFIK KALORI
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