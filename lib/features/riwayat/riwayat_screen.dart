import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// SESUAIKAN dengan key JWT yang dipakai halaman login.
const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);

/// Jumlah log yang tampil sebelum tombol "Lihat semua".
const int _kLogAwal = 7;
// Jika nama key dari backend berbeda, cukup ubah di fromJson.
double? _toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

class CycleHistory {
  final String id;
  final String tujuan;
  final double bbAwal;
  final double bbTujuan;
  final int durasiHari;
  final double? targetKalori;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  final int nomor;

  const CycleHistory({
    required this.id,
    required this.tujuan,
    required this.bbAwal,
    required this.bbTujuan,
    required this.durasiHari,
    required this.targetKalori,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.nomor = 0,
  });

  bool get isActive => status == 'aktif';

  String get cycleNumber => 'Siklus #${nomor.toString().padLeft(2, '0')}';

  String get labelTujuan {
    switch (tujuan) {
      case 'turun_bb':
        return 'Turun BB';
      case 'naik_bb':
        return 'Naik BB';
      default:
        return 'Target BB';
    }
  }

  String get title =>
      '$labelTujuan: ${bbAwal.toStringAsFixed(1)} → ${bbTujuan.toStringAsFixed(1)} kg';

  int get sisaHari => startDate.add(Duration(days: durasiHari)).difference(DateTime.now()).inDays;

  CycleHistory withNomor(int n) => CycleHistory(
        id: id,
        tujuan: tujuan,
        bbAwal: bbAwal,
        bbTujuan: bbTujuan,
        durasiHari: durasiHari,
        targetKalori: targetKalori,
        startDate: startDate,
        endDate: endDate,
        status: status,
        nomor: n,
      );

  factory CycleHistory.fromJson(Map<String, dynamic> j) {
    return CycleHistory(
      id: j['id'].toString(),
      tujuan: (j['tujuan'] ?? '').toString(),
      bbAwal: _toDouble(j['bb_awal_kg']) ?? 0,
      bbTujuan: _toDouble(j['bb_tujuan_kg']) ?? 0,
      durasiHari: _toInt(j['durasi_hari']) ?? 0,
      targetKalori: _toDouble(j['target_kalori_per_hari']),
      startDate:
          DateTime.tryParse((j['tanggal_mulai'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      endDate: DateTime.tryParse((j['tanggal_selesai'] ?? '').toString())?.toLocal(),
      status: (j['status'] ?? '').toString().toLowerCase(),
    );
  }
}

class DailyLog {
  final DateTime date;
  final int caloriesIn;
  final int caloriesOut;

  const DailyLog({required this.date, required this.caloriesIn, required this.caloriesOut});

  int get selisih => caloriesOut - caloriesIn;

  factory DailyLog.fromJson(Map<String, dynamic> j) {
    return DailyLog(
      date: DateTime.tryParse((j['tanggal'] ?? j['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      caloriesIn: _toDouble(j['kalori_masuk'])?.round() ?? 0,
      caloriesOut: _toDouble(j['kalori_keluar'])?.round() ?? 0,
    );
  }
}

// DATA: API + DUMMY

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

String _pesanError(Object e, {String fallback = 'Terjadi kesalahan. Silakan coba lagi.'}) {
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
  return fallback;
}

List<dynamic> _ambilList(dynamic body, [String? key]) {
  if (body is List) return body;
  if (body is Map) {
    final data = body['data'] ?? (key == null ? null : body[key]);
    if (data is List) return data;
  }
  return const [];
}

class _RiwayatRepository {
  Future<void> _tunda([int ms = 500]) => Future.delayed(Duration(milliseconds: ms));

  Future<List<CycleHistory>> ambilSiklus() async {
    List<CycleHistory> hasil;

    if (_kPakaiMock) {
      await _tunda();
      hasil = _siklusContoh();
    } else {
      final res = await _buatDio().get('/klien/progress-cycles');
      hasil = _ambilList(res.data, 'cycles')
          .whereType<Map<String, dynamic>>()
          .map(CycleHistory.fromJson)
          .toList();
    }

    hasil.sort((a, b) => a.startDate.compareTo(b.startDate));
    final bernomor = <CycleHistory>[
      for (var i = 0; i < hasil.length; i++) hasil[i].withNomor(i + 1),
    ];
    return bernomor.reversed.toList();
  }

  Future<List<DailyLog>> ambilLog(CycleHistory c) async {
    List<DailyLog> logs;

    if (_kPakaiMock) {
      await _tunda(700);
      logs = _logContoh(c);
    } else {
      final res = await _buatDio().get('/klien/progress-cycles/${c.id}/logs');
      logs = _ambilList(res.data, 'logs')
          .whereType<Map<String, dynamic>>()
          .map(DailyLog.fromJson)
          .toList();
    }

    logs.sort((a, b) => b.date.compareTo(a.date)); // terbaru dulu
    return logs;
  }

  List<CycleHistory> _siklusContoh() {
    final now = DateTime.now();
    DateTime hariLalu(int n) => DateTime(now.year, now.month, now.day).subtract(Duration(days: n));

    return [
      CycleHistory(
        id: 'c3',
        tujuan: 'turun_bb',
        bbAwal: 72.0,
        bbTujuan: 67.0,
        durasiHari: 60,
        targetKalori: 1980,
        startDate: hariLalu(41),
        endDate: null,
        status: 'aktif',
      ),
      CycleHistory(
        id: 'c2',
        tujuan: 'turun_bb',
        bbAwal: 76.5,
        bbTujuan: 72.0,
        durasiHari: 45,
        targetKalori: 2050,
        startDate: hariLalu(110),
        endDate: hariLalu(66),
        status: 'selesai',
      ),
      CycleHistory(
        id: 'c1',
        tujuan: 'naik_bb',
        bbAwal: 78.5,
        bbTujuan: 80.0,
        durasiHari: 30,
        targetKalori: 2400,
        startDate: hariLalu(180),
        endDate: hariLalu(150),
        status: 'selesai',
      ),
    ];
  }

  List<DailyLog> _logContoh(CycleHistory c) {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final akhir = c.endDate ?? hariIni;
    final jumlah = akhir.difference(DateTime(c.startDate.year, c.startDate.month, c.startDate.day)).inDays + 1;
    final n = jumlah.clamp(1, 30);

    return [
      for (var i = 0; i < n; i++)
        DailyLog(
          date: akhir.subtract(Duration(days: i)),
          caloriesIn: 1600 + ((i * 37) % 260),
          caloriesOut: 1950 + ((i * 53) % 320),
        ),
    ];
  }
}

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _repo = _RiwayatRepository();

  String _selectedFilter = 'Semua Siklus';
  bool _isLoading = true;
  String? _error;
  List<CycleHistory> _historyData = [];

  final Set<String> _expanded = {};
  final Set<String> _showAll = {};
  final Map<String, List<DailyLog>> _logs = {};
  final Set<String> _loadingLogs = {};
  final Map<String, String> _logErrors = {};

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final data = await _repo.ambilSiklus();
      if (!mounted) return;
      setState(() {
        _historyData = data;
        _expanded.clear();
        _showAll.clear();
        _logs.clear();
        _loadingLogs.clear();
        _logErrors.clear();
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _pesanError(e, fallback: 'Gagal memuat riwayat siklus.');
        _isLoading = false;
      });
    }
  }

  Future<void> _muatLog(CycleHistory c) async {
    setState(() {
      _loadingLogs.add(c.id);
      _logErrors.remove(c.id);
    });
    try {
      final logs = await _repo.ambilLog(c);
      if (!mounted) return;
      setState(() {
        _logs[c.id] = logs;
        _loadingLogs.remove(c.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logErrors[c.id] = _pesanError(e, fallback: 'Gagal memuat log harian.');
        _loadingLogs.remove(c.id);
      });
    }
  }

  void _toggle(CycleHistory c) {
    setState(() {
      if (!_expanded.add(c.id)) _expanded.remove(c.id);
    });
    if (_expanded.contains(c.id) && !_logs.containsKey(c.id) && !_loadingLogs.contains(c.id)) {
      _muatLog(c);
    }
  }

  List<CycleHistory> get _filteredData {
    if (_selectedFilter == 'Selesai') {
      return _historyData.where((c) => !c.isActive).toList();
    } else if (_selectedFilter == 'Sedang Berjalan') {
      return _historyData.where((c) => c.isActive).toList();
    }
    return _historyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _oranye))
            : RefreshIndicator(
                color: _oranye,
                backgroundColor: context.card,
                onRefresh: () => _fetchHistoryData(silent: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 12),
                    const BugarinHeader(subtitle: 'Riwayat'),
                    const SizedBox(height: 20),
                    _buildHeaderTexts(context),
                    const SizedBox(height: 24),
                    if (_error != null)
                      _buildError()
                    else ...[
                      _buildFilters(context),
                      const SizedBox(height: 24),
                      if (_filteredData.isEmpty) _buildKosong(),
                      for (final cycle in _filteredData)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CycleExpandableCard(
                            cycle: cycle,
                            expanded: _expanded.contains(cycle.id),
                            loading: _loadingLogs.contains(cycle.id),
                            error: _logErrors[cycle.id],
                            logs: _logs[cycle.id],
                            showAll: _showAll.contains(cycle.id),
                            onToggle: () => _toggle(cycle),
                            onRetry: () => _muatLog(cycle),
                            onToggleShowAll: () => setState(() {
                              if (!_showAll.add(cycle.id)) _showAll.remove(cycle.id);
                            }),
                          ),
                        ),
                    ],
                    const SizedBox(height: 120), // ruang agar tidak tertutup bottom nav
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchHistoryData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _oranye,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          _historyData.isEmpty
              ? 'Belum ada riwayat siklus.'
              : 'Tidak ada siklus pada kategori ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildHeaderTexts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Siklus',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Arsip target, capaian metabolisme, dan rincian log harian secara menyeluruh.',
          style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filters = [
      {'label': 'Semua Siklus', 'count': _historyData.length},
      {'label': 'Selesai', 'count': _historyData.where((c) => !c.isActive).length},
      {'label': 'Sedang Berjalan', 'count': _historyData.where((c) => c.isActive).length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _oranye.withValues(alpha: 0.15) : context.surfaceInner,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? _oranye.withValues(alpha: 0.5) : context.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isSelected ? _oranye : context.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? _oranye : context.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${f['count']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CycleExpandableCard extends StatelessWidget {
  const _CycleExpandableCard({
    required this.cycle,
    required this.expanded,
    required this.loading,
    required this.error,
    required this.logs,
    required this.showAll,
    required this.onToggle,
    required this.onRetry,
    required this.onToggleShowAll,
  });

  final CycleHistory cycle;
  final bool expanded;
  final bool loading;
  final String? error;
  final List<DailyLog>? logs;
  final bool showAll;
  final VoidCallback onToggle;
  final VoidCallback onRetry;
  final VoidCallback onToggleShowAll;

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _ribuan(num value) {
    return value.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = cycle;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.isActive ? _oranye.withValues(alpha: 0.5) : context.border),
          boxShadow: [
            if (expanded)
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS ATAS: label status, nomor siklus, panah
            Row(
              children: [
                if (c.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _oranye.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline_rounded, color: _oranye, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Berjalan',
                          style: TextStyle(
                            color: _oranye,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: context.textSecondary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          c.endDate == null ? 'Selesai' : 'Selesai: ${_formatDate(c.endDate!)}',
                          style: TextStyle(color: context.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.cycleNumber,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.keyboard_arrow_down, color: context.textPrimary, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              c.title,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai: ${_formatDate(c.startDate)} • Durasi: ${c.durasiHari} hari',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),

            if (c.isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _oranye.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c.sisaHari >= 0
                      ? 'Sisa ${c.sisaHari} Hari'
                      : 'Durasi terlewat ${-c.sisaHari} hari',
                  style: const TextStyle(
                    color: _oranye,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatPill(context, 'Target BB', '${c.bbTujuan.toStringAsFixed(1)} kg', _oranye),
                _buildStatPill(context, 'Durasi', '${c.durasiHari} Hari', context.textPrimary),
                _buildStatPill(
                  context,
                  'Target Kalori',
                  c.targetKalori == null ? '-' : '${_ribuan(c.targetKalori!)} kkal',
                  context.textSecondary,
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? _buildDetail(context)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(color: context.border, height: 1, thickness: 1),
    );

    if (loading) {
      return Column(
        children: [
          divider,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: _oranye, strokeWidth: 2.2),
            ),
          ),
        ],
      );
    }

    if (error != null) {
      return Column(
        children: [
          divider,
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi', style: TextStyle(color: _oranye)),
          ),
        ],
      );
    }

    final data = logs;
    if (data == null) return const SizedBox(width: double.infinity);

    if (data.isEmpty) {
      return Column(
        children: [
          divider,
          Text(
            'Belum ada log pada siklus ini.',
            style: TextStyle(color: context.textMuted, fontSize: 12),
          ),
        ],
      );
    }

    final avgIn = (data.fold<int>(0, (s, l) => s + l.caloriesIn) / data.length).round();
    final avgOut = (data.fold<int>(0, (s, l) => s + l.caloriesOut) / data.length).round();
    final tampil = showAll ? data : data.take(_kLogAwal).toList();
    final adaLebih = data.length > _kLogAwal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        divider,
        _buildStatRow(context, Icons.restaurant, 'Rata-rata masuk:', '${_ribuan(avgIn)} kkal', _oranye),
        const SizedBox(height: 8),
        _buildStatRow(context, Icons.local_fire_department, 'Rata-rata keluar:',
            '${_ribuan(avgOut)} kkal', Colors.redAccent),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LOG HARIAN SIKLUS',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _oranye.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${data.length} hari tercatat',
                style: const TextStyle(color: _oranye, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < tampil.length; i++)
          _buildTimelineItem(context, tampil[i], isLast: i == tampil.length - 1),
        if (adaLebih) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: context.surfaceInner,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onToggleShowAll,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    showAll ? 'Tampilkan lebih sedikit' : 'Lihat Seluruh Log Harian (${data.length})',
                    style: const TextStyle(
                      color: _oranye,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    showAll ? Icons.keyboard_arrow_up_rounded : Icons.arrow_forward,
                    color: _oranye,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatPill(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, DailyLog log, {required bool isLast}) {
    final defisit = log.selisih >= 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _oranye,
                    boxShadow: [
                      BoxShadow(
                        color: _oranye.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _oranye.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(log.date),
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Masuk: ${_ribuan(log.caloriesIn)} kkal',
                          style: const TextStyle(color: _oranye, fontSize: 12)),
                      Text('  •  ', style: TextStyle(color: context.textSecondary)),
                      Text('Keluar: ${_ribuan(log.caloriesOut)} kkal',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: defisit ? _oranye.withValues(alpha: 0.15) : context.surfaceInner,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      defisit
                          ? 'Defisit ${_ribuan(log.selisih)} kkal'
                          : 'Surplus ${_ribuan(-log.selisih)} kkal',
                      style: TextStyle(
                        color: defisit ? _oranye : context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}