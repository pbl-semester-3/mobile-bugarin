import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_screen.g.dart';

// Model Data Kontrak Backend
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

// Provider Riverpod (Sinkron dengan .g.dart)
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  const storage = FlutterSecureStorage();
  final savedTarget = await storage.read(key: 'daily_calorie_target');
  final savedName = await storage.read(key: 'user_name');

  return DashboardSummary(
    userName: (savedName != null && savedName.isNotEmpty) ? savedName : 'Maya',
    cycleDay: 14,
    targetCalories: savedTarget != null ? int.tryParse(savedTarget) ?? 1980 : 1980,
    consumedCalories: 1420,
    streakDays: 12,
  );
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Key unik untuk memaksa animasi berputar ulang saat layar disentuh
  Key _gaugeAnimationKey = UniqueKey();

  void _replayAnimation() {
    setState(() {
      _gaugeAnimationKey = UniqueKey();
    });
  }

  String _formatKcal(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090E0C),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3EE5B4),
              strokeWidth: 2.2,
            ),
          ),
          error: (err, _) => Center(
            child: Text('Gagal memuat: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (data) {
            // Rasio progres kalori (misal 1420 / 1980 = ~71.7%)
            final double progressRatio = (data.consumedCalories /
                    (data.targetCalories == 0 ? 1 : data.targetCalories))
                .clamp(0.0, 1.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF111E19),
                              border: Border.all(
                                color: const Color(0xFF3EE5B4).withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'B',
                                style: TextStyle(
                                  color: Color(0xFF3EE5B4),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUGARIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Beranda',
                                style: TextStyle(
                                  color: Color(0xFF8A9992),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3EE5B4).withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Header Sambutan
                  Text(
                    'Selamat Datang, ${data.userName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hari ke-${data.cycleDay} Siklus Transformasi',
                    style: const TextStyle(
                      color: Color(0xFF8A9992),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // KARTU BESAR KALORI & STREAK (BISA DIKETUK UNTUK REPLAY)
                  GestureDetector(
                    onTap: _replayAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111A16),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFF1A2822),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // AREA GAUGE: MENGGUNAKAN TWEENANIMATIONBUILDER (PASTI JALAN DARI 0)
                          SizedBox(
                            height: 210,
                            child: TweenAnimationBuilder<double>(
                              key: _gaugeAnimationKey,
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1800),
                              curve: Curves.easeOutCubic,
                              builder: (context, animValue, _) {
                                // Angka kalori menghitung naik secara dinamis dari 0 ke target
                                final animatedConsumed = (data.consumedCalories * animValue).round();
                                final animatedRemaining = (data.targetCalories - animatedConsumed)
                                    .clamp(0, data.targetCalories);

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(210, 210),
                                      painter: _LiveFlowingArcPainter(
                                        progress: progressRatio * animValue,
                                        strokeWidth: 14.0,
                                        trackColor: const Color(0xFF17241F), // Rel redup
                                        activeColor: const Color(0xFF3EE5B4), // Mint mengalir
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatKcal(animatedConsumed),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'DARI ${_formatKcal(data.targetCalories)} KKAL',
                                          style: const TextStyle(
                                            color: Color(0xFF8A9992),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tersisa $animatedRemaining kkal',
                                          style: const TextStyle(
                                            color: Color(0xFF8A9992),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Kartu Streak Konsistensi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16221D),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF1D2E27),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1B2C24),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFF3EE5B4),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${data.streakDays} Hari',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'Beruntun',
                                          style: TextStyle(
                                            color: Color(0xFF8A9992),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Ritme Konsisten',
                                      style: TextStyle(
                                        color: Color(0xFF5A6B64),
                                        fontSize: 11,
                                      ),
                                    ),
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

                  // Header Jadwal Sesi Hari Ini
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Jadwal Sesi Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lihat Kalender',
                        style: TextStyle(
                          color: Color(0xFF8A9992),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // KARTU COACH SARAH JENKINS
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF1A2822),
                        width: 1.2,
                      ),
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
                                border: Border.all(
                                  color: const Color(0xFF3EE5B4),
                                  width: 1.8,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=200',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coach Sarah Jenkins',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Calisthenics & Hypertrophy Lead',
                                    style: TextStyle(
                                      color: Color(0xFF8A9992),
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF3EE5B4)),
                                      SizedBox(width: 5),
                                      Text(
                                        'Hari ini, 16:30 - 17:30 WIB',
                                        style: TextStyle(color: Color(0xFF8A9992), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF3EE5B4)),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'FitZone Senopati • Studio B',
                                          style: TextStyle(color: Color(0xFF8A9992), fontSize: 11),
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

                        // Tombol Aksi
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3EE5B4),
                                    foregroundColor: const Color(0xFF090E0C),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Masuk Sesi Latihan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16221D),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF22332B)),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF3EE5B4),
                                  size: 18,
                                ),
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

// PAINTER BUSUR GAUGE DENGAN REPAINT AKTIF
class _LiveFlowingArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color activeColor;

  _LiveFlowingArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Busur kanan: mulai dari atas (-70 derajat) memutar searah jarum jam sejauh 180 derajat
    const startAngle = -70 * (math.pi / 180);
    const totalSweep = 180 * (math.pi / 180);

    // 1. Gambar rel jalur redup
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

    // 2. Gambar cairan mint yang meluncur mengisi rel
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

  // Wajib return true agar setiap perpindahan frame di-repaint mulus di browser web
  @override
  bool shouldRepaint(covariant _LiveFlowingArcPainter oldDelegate) => true;
}