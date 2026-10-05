import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';
import '../../shell/shell_tab.dart';

part 'dashboard_screen.g.dart';

// ============================================================================
// KONFIGURASI
// ============================================================================

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// SESUAIKAN dengan key JWT yang dipakai halaman login.
const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);

// ============================================================================
// MODEL  (GET /klien/dashboard-summary)
// Jika nama key dari backend berbeda, cukup ubah di fromJson.
// ============================================================================

int _toInt(dynamic v) => v == null ? 0 : (num.tryParse(v.toString())?.round() ?? 0);

class PtAktif {
  final String nama;
  final String spesialisasi;
  final String? fotoUrl;
  final String? tempatGym;

  const PtAktif({
    required this.nama,
    required this.spesialisasi,
    required this.fotoUrl,
    required this.tempatGym,
  });

  factory PtAktif.fromJson(Map<String, dynamic> j) => PtAktif(
        nama: (j['nama'] ?? '').toString(),
        spesialisasi: (j['spesialisasi'] ?? '').toString(),
        fotoUrl: (j['foto_url'] ?? j['foto_profil'])?.toString(),
        tempatGym: (j['tempat_gym'] ?? j['lokasi'])?.toString(),
      );
}

class JadwalLatihan {
  final String hari;
  final String jam;
  final String jenis;

  const JadwalLatihan({required this.hari, required this.jam, required this.jenis});

  factory JadwalLatihan.fromJson(Map<String, dynamic> j) => JadwalLatihan(
        hari: (j['hari'] ?? '').toString(),
        jam: (j['jam'] ?? '').toString(),
        jenis: (j['jenis'] ?? '').toString(),
      );
}

class DashboardSummary {
  final String userName;
  final int cycleDay;
  final int durasiHari;
  final int targetCalories;
  final int consumedCalories;
  final int streakDays;
  final PtAktif? pt; // null = klien belum punya PT
  final String? planStatus; // mis. approved | pending_review
  final List<JadwalLatihan> jadwal;
  final bool durasiLewat; // banner reminder

  const DashboardSummary({
    required this.userName,
    required this.cycleDay,
    required this.durasiHari,
    required this.targetCalories,
    required this.consumedCalories,
    required this.streakDays,
    required this.pt,
    required this.planStatus,
    required this.jadwal,
    required this.durasiLewat,
  });

  bool get planDisetujui => planStatus != null && planStatus != 'pending_review';

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    final rawPt = j['pt'] ?? j['pt_aktif'];
    final rawJadwal = j['jadwal'] ?? j['workout_plan'];
    final nama = (j['nama'] ?? j['user_name'] ?? '').toString().trim();

    return DashboardSummary(
      userName: nama.isEmpty ? 'Klien' : nama.split(' ').first,
      cycleDay: _toInt(j['hari_ke']),
      durasiHari: _toInt(j['durasi_hari']),
      targetCalories: _toInt(j['target_kalori_per_hari']),
      consumedCalories: _toInt(j['kalori_masuk_hari_ini']),
      streakDays: _toInt(j['streak_hari']),
      pt: rawPt is Map<String, dynamic> ? PtAktif.fromJson(rawPt) : null,
      planStatus: (j['weekly_plan_status'] ?? j['plan_status'])?.toString(),
      jadwal: rawJadwal is List
          ? rawJadwal
              .whereType<Map<String, dynamic>>()
              .map(JadwalLatihan.fromJson)
              .toList()
          : const [],
      durasiLewat: j['reminder_durasi_lewat'] == true,
    );
  }
}

// ============================================================================
// DATA: API + DUMMY
// ============================================================================

Dio _buatDio() {
  const storage = FlutterSecureStorage();
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: _kTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

String _pesanError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      default:
        break;
    }
  }
  return 'Gagal memuat beranda. Silakan coba lagi.';
}

String? _resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = Uri.parse(_kBaseUrl).origin;
  return url.startsWith('/') ? '$origin$url' : '$origin/$url';
}

/// Data contoh. Untuk menguji kondisi lain, ubah nilainya:
///  - 'pt': null                          -> klien belum punya PT
///  - 'weekly_plan_status': 'pending_review' -> menunggu PT menyetujui rencana
///  - 'reminder_durasi_lewat': true       -> banner reminder tampil
Map<String, dynamic> _dataContoh() => {
      'nama': 'Maya Ayuningsih',
      'hari_ke': 14,
      'durasi_hari': 60,
      'target_kalori_per_hari': 2175,
      'kalori_masuk_hari_ini': 1420,
      'streak_hari': 12,
      'pt': {
        'nama': 'Coach Sarah Jenkins',
        'spesialisasi': 'Calisthenics & Hypertrophy',
        'foto_url': null,
        'tempat_gym': 'FitZone Studio B, Senopati',
      },
      'weekly_plan_status': 'approved',
      'jadwal': [
        {'hari': 'Senin', 'jam': '16:30 - 17:30 WIB', 'jenis': 'Upper Body Strength'},
        {'hari': 'Rabu', 'jam': '16:30 - 17:30 WIB', 'jenis': 'Lower Body & Core'},
        {'hari': 'Jumat', 'jam': '16:30 - 17:30 WIB', 'jenis': 'Full Body Circuit'},
      ],
      'reminder_durasi_lewat': false,
    };

/// Signature fungsi ini sengaja tidak diubah, sehingga dashboard_screen.g.dart
/// yang sudah ada tetap valid (tidak perlu menjalankan build_runner lagi).
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  if (_kPakaiMock) {
    await Future.delayed(const Duration(milliseconds: 500));
    return DashboardSummary.fromJson(_dataContoh());
  }

  final res = await _buatDio().get('/klien/dashboard-summary');
  final body = res.data;
  Map<String, dynamic> map = {};
  if (body is Map<String, dynamic>) {
    final data = body['data'];
    map = data is Map<String, dynamic> ? data : body;
  }
  return DashboardSummary.fromJson(map);
}

// ============================================================================
// LAYAR
// ============================================================================

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _curvedAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerReplay() => _animController.forward(from: 0.0);

  String _formatKcal(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _segarkan() async {
    ref.invalidate(dashboardSummaryProvider);
    try {
      await ref.read(dashboardSummaryProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Memicu animasi saat data selesai dimuat (termasuk setelah refresh).
    ref.listen<AsyncValue<DashboardSummary>>(dashboardSummaryProvider, (previous, next) {
      if (next.hasValue && (previous == null || previous.isLoading)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animController.forward(from: 0.0);
        });
      }
    });

    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _oranye, strokeWidth: 2.2),
          ),
          error: (err, _) => _buildError(err),
          data: (data) => RefreshIndicator(
            color: _oranye,
            onRefresh: _segarkan,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BugarinHeader(subtitle: 'Beranda'),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat Datang, ${data.userName}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (data.cycleDay > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hari ke-${data.cycleDay} Siklus Transformasi',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildKaloriCard(data),
                  const SizedBox(height: 26),
                  Text(
                    'Jadwal Latihan Bareng PT',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPtCard(data),
                  if (data.durasiLewat) ...[
                    const SizedBox(height: 16),
                    _buildBannerReminder(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- BAGIAN

  Widget _buildError(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              _pesanError(err),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(dashboardSummaryProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _oranye,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKaloriCard(DashboardSummary data) {
    final double targetProgress = data.targetCalories == 0
        ? 0.0
        : (data.consumedCalories / data.targetCalories).clamp(0.0, 1.0).toDouble();

    return GestureDetector(
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
                  final animatedRemaining =
                      (data.targetCalories - animatedConsumed).clamp(0, data.targetCalories);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(210, 210),
                        painter: LiveArcPainter(
                          progress: targetProgress * animVal,
                          strokeWidth: 14.0,
                          trackColor: context.isDark
                              ? const Color(0xFF162520)
                              : const Color(0xFFE2E8E5),
                          activeColor: _oranye,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatKcal(animatedConsumed),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DARI ${_formatKcal(data.targetCalories)} KKAL',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tersisa $animatedRemaining kkal',
                            style: TextStyle(
                              color: context.textSecondary,
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
                    child: const Icon(Icons.local_fire_department_rounded, color: _oranye, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${data.streakDays} Hari',
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Text('Beruntun',
                              style: TextStyle(color: context.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.streakDays > 0 ? 'Ritme Konsisten' : 'Catat aktivitas hari ini',
                        style: TextStyle(color: context.textMuted, fontSize: 11),
                      ),
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

  Widget _kotak({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 1.2),
      ),
      child: child,
    );
  }

  /// Aturan PRD 3.3:
  ///  - pt == null            -> ajakan ke tab "PT ku"
  ///  - rencana belum disetujui -> state "menunggu PT"
  ///  - rencana disetujui     -> jadwal + lokasi gym
  Widget _buildPtCard(DashboardSummary data) {
    final pt = data.pt;

    if (pt == null) {
      return _kotak(
        child: Column(
          children: [
            const Icon(Icons.person_search_rounded, color: _oranye, size: 34),
            const SizedBox(height: 10),
            Text(
              'Anda belum memiliki PT',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih personal trainer untuk mendapatkan jadwal latihan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => shellTabIndex.value = 1, // buka tab PT ku
                style: ElevatedButton.styleFrom(
                  backgroundColor: _oranye,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Pilih PT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    final fotoUrl = _resolveMediaUrl(pt.fotoUrl);
    final inisial = pt.nama.trim().isEmpty ? '?' : pt.nama.trim()[0].toUpperCase();
    final adaJadwal = data.planDisetujui && data.jadwal.isNotEmpty;

    return _kotak(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surfaceInner,
                  border: Border.all(color: _oranye, width: 1.8),
                  image: fotoUrl == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(fotoUrl),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                ),
                child: fotoUrl == null
                    ? Center(
                        child: Text(
                          inisial,
                          style: const TextStyle(
                            color: _oranye,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pt.nama,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pt.spesialisasi,
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!adaJadwal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16, color: _oranye),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.planDisetujui
                          ? 'Belum ada jadwal latihan minggu ini.'
                          : 'Menunggu PT menyetujui rencana latihan mingguan Anda.',
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final j in data.jadwal) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.jenis,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: _oranye),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${j.hari}, ${j.jam}',
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (pt.tempatGym != null && pt.tempatGym!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _oranye),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      pt.tempatGym!,
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBannerReminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4DFF5520)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: _oranye, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Durasi progres Anda sudah lewat dan target belum tercapai. '
              'Tetap semangat, perbarui progres Anda.',
              style: TextStyle(color: _oranye, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER UNTUK GRAFIK KALORI
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