import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

part 'feedback_screen.g.dart';

const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// SESUAIKAN dengan key JWT yang dipakai halaman login.
const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);

// Jika nama key dari backend berbeda, cukup ubah di fromJson.

enum SenderType { ai, coach }

enum ReplyStatus { none, replied, waiting }

class FeedbackModel {
  final String id;
  final SenderType senderType;
  final String senderName;
  final String senderRole;
  final DateTime createdAt;
  final String content;
  final bool dibaca;
  final String? senderPhotoUrl;

  final String? caloryStat;
  final String? sleepStat;
  final String? coachTag;

  final String? userReply;
  final DateTime? replyTime;

  const FeedbackModel({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
    required this.content,
    this.dibaca = true,
    this.senderPhotoUrl,
    this.caloryStat,
    this.sleepStat,
    this.coachTag,
    this.userReply,
    this.replyTime,
  });

  ReplyStatus get replyStatus {
    if (senderType == SenderType.ai) return ReplyStatus.none;
    final r = userReply;
    return (r != null && r.trim().isNotEmpty) ? ReplyStatus.replied : ReplyStatus.waiting;
  }

  FeedbackModel copyWith({bool? dibaca, String? userReply, DateTime? replyTime}) {
    return FeedbackModel(
      id: id,
      senderType: senderType,
      senderName: senderName,
      senderRole: senderRole,
      createdAt: createdAt,
      content: content,
      dibaca: dibaca ?? this.dibaca,
      senderPhotoUrl: senderPhotoUrl,
      caloryStat: caloryStat,
      sleepStat: sleepStat,
      coachTag: coachTag,
      userReply: userReply ?? this.userReply,
      replyTime: replyTime ?? this.replyTime,
    );
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> j) {
    final pengirim = (j['pengirim'] ?? j['sender_type'] ?? j['tipe'] ?? '').toString().toLowerCase();
    final isAi = pengirim == 'ai';
    final rawPt = j['pt'];
    final pt = rawPt is Map<String, dynamic> ? rawPt : const <String, dynamic>{};
    final namaPt = (pt['nama'] ?? j['nama_pt'] ?? '').toString();
    final rawDibaca = j['dibaca'];

    return FeedbackModel(
      id: j['id'].toString(),
      senderType: isAi ? SenderType.ai : SenderType.coach,
      senderName: isAi ? 'BUGARIN AI' : (namaPt.isEmpty ? 'Coach' : 'Coach $namaPt'),
      senderRole: isAi ? 'Evaluasi Siklus' : 'Personal Trainer',
      createdAt: DateTime.tryParse((j['created_at'] ?? j['waktu'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      content: (j['isi'] ?? j['pesan'] ?? j['content'] ?? '').toString(),
      dibaca: rawDibaca == null ? true : (rawDibaca == true || rawDibaca == 1),
      senderPhotoUrl: (pt['foto_url'] ?? pt['foto_profil'])?.toString(),
      caloryStat: j['stat_kalori']?.toString(),
      sleepStat: j['stat_istirahat']?.toString(),
      coachTag: j['tag']?.toString(),
      userReply: j['balasan_klien']?.toString(),
      replyTime: DateTime.tryParse((j['dibalas_pada'] ?? '').toString())?.toLocal(),
    );
  }
}

String _formatWaktu(DateTime t) {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
  final now = DateTime.now();
  final hari = DateTime(t.year, t.month, t.day);
  final hariIni = DateTime(now.year, now.month, now.day);
  final selisih = hariIni.difference(hari).inDays;
  final jam = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  if (selisih == 0) {
    final menit = now.difference(t).inMinutes;
    if (menit >= 0 && menit < 60) return menit < 1 ? 'Baru saja' : '$menit menit lalu';
    return 'Hari ini, $jam';
  }
  if (selisih == 1) return 'Kemarin, $jam';
  return '${t.day} ${bulan[t.month - 1]}, $jam';
}

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

String? _resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = Uri.parse(_kBaseUrl).origin;
  return url.startsWith('/') ? '$origin$url' : '$origin/$url';
}

class _FeedbackRepository {
  static List<FeedbackModel>? _mock;

  static List<FeedbackModel> _dataContoh() {
    final now = DateTime.now();
    const foto = 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=200';
    return [
      FeedbackModel(
        id: '1',
        senderType: SenderType.ai,
        senderName: 'BUGARIN AI',
        senderRole: 'Evaluasi Siklus',
        createdAt: now.subtract(const Duration(hours: 2)),
        dibaca: false,
        caloryStat: 'Defisit Kalori: -520 kcal',
        sleepStat: 'Kualitas Istirahat: 88%',
        content:
            'Analisis asupan nutrisi 3 hari terakhir menunjukkan konsistensi protein yang sangat baik (rata-rata 115g). Disarankan menambah hidrasi +500ml sebelum sesi intensif besok untuk menjaga regenerasi otot.',
      ),
      FeedbackModel(
        id: '2',
        senderType: SenderType.coach,
        senderName: 'Coach Sarah Jenkins',
        senderRole: 'Personal Trainer',
        createdAt: now.subtract(const Duration(days: 1)),
        senderPhotoUrl: foto,
        coachTag: 'Form Check • Romanian Deadlift',
        content:
            'Form deadlift kamu di set ke-3 terlihat jauh lebih stabil di bagian punggung bawah. Pastikan tetap tahan napas di diafragma sebelum mengangkat beban. Pertahankan tempo ini!',
        userReply: 'Terima kasih coach, saya akan perbaiki postur dan fokus pada brace core.',
        replyTime: now.subtract(const Duration(days: 1, minutes: -25)),
      ),
      FeedbackModel(
        id: '3',
        senderType: SenderType.coach,
        senderName: 'Coach Sarah Jenkins',
        senderRole: 'Personal Trainer',
        createdAt: now.subtract(const Duration(minutes: 10)),
        dibaca: false,
        senderPhotoUrl: foto,
        content:
            'Halo! Berdasarkan catatan peregangan panggul tadi pagi, apakah ada rasa nyeri berlebih di area hamstring kanan? Jika ada, kita sesuaikan intensitas gerakan leg curl besok.',
      ),
      FeedbackModel(
        id: '4',
        senderType: SenderType.ai,
        senderName: 'BUGARIN AI',
        senderRole: 'Evaluasi Siklus',
        createdAt: now.subtract(const Duration(days: 3)),
        content:
            'Asupan kalori Anda stabil dalam rentang target selama 5 hari berturut-turut. Pertahankan pola makan ini dan pastikan sarapan tidak terlewat.',
      ),
    ];
  }

  Future<void> _tunda([int ms = 500]) => Future.delayed(Duration(milliseconds: ms));

  void _ubahContoh(String id, FeedbackModel Function(FeedbackModel) ubah) {
    _mock = [for (final f in _mock ?? _dataContoh()) f.id == id ? ubah(f) : f];
  }

  Future<List<FeedbackModel>> ambilSemua() async {
    List<FeedbackModel> hasil;

    if (_kPakaiMock) {
      await _tunda();
      _mock ??= _dataContoh();
      hasil = List.of(_mock!);
    } else {
      final res = await _buatDio().get('/klien/feedbacks');
      final body = res.data;
      final list = body is List ? body : (body is Map ? (body['data'] ?? body['feedbacks']) : null);
      hasil = list is List
          ? list.whereType<Map<String, dynamic>>().map(FeedbackModel.fromJson).toList()
          : <FeedbackModel>[];
    }

    hasil.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // terbaru di atas
    return hasil;
  }

  Future<void> balas(String id, String teks) async {
    if (_kPakaiMock) {
      await _tunda(600);
      _ubahContoh(id, (f) => f.copyWith(userReply: teks, replyTime: DateTime.now(), dibaca: true));
      return;
    }
    await _buatDio().post('/klien/feedbacks/$id/reply', data: {'balasan_klien': teks});
  }

  /// PUT /klien/feedbacks/:id/read
  Future<void> tandaiDibaca(String id) async {
    if (_kPakaiMock) {
      _ubahContoh(id, (f) => f.copyWith(dibaca: true));
      return;
    }
    await _buatDio().put('/klien/feedbacks/$id/read');
  }
}

final _feedbackRepositoryProvider = Provider<_FeedbackRepository>((ref) => _FeedbackRepository());

@riverpod
Future<List<FeedbackModel>> feedbackList(Ref ref) async {
  return ref.read(_feedbackRepositoryProvider).ambilSemua();
}

/// Jumlah feedback yang belum dibaca (dibaca = false).
/// Pakai di MainShell untuk badge ikon tab Feedback:
///   final unread = ref.watch(feedbackUnreadCountProvider);
final feedbackUnreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(feedbackListProvider);
  return async.maybeWhen(
    data: (list) => list.where((f) => !f.dibaca).length,
    orElse: () => 0,
  );
});

class FeedbackScreen extends ConsumerStatefulWidget {
  /// Diisi MainShell: true hanya saat tab Feedback sedang dibuka.
  /// Feedback baru ditandai "dibaca" hanya ketika isActive = true, karena
  /// IndexedStack membangun semua tab sejak aplikasi dibuka.
  final bool isActive;

  const FeedbackScreen({super.key, this.isActive = true});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _selectedFilter = 0;

  final Map<String, TextEditingController> _replyCtrls = {};
  final Set<String> _sending = {};
  final Set<String> _readRequested = {};
  Timer? _refreshTimer;

  TextEditingController _ctrl(String id) =>
      _replyCtrls.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (final c in _replyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String pesan, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _merah : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(pesan),
        ),
      );
  }

  void _tandaiDibacaBilaPerlu(FeedbackModel f) {
    if (!widget.isActive || f.dibaca || !_readRequested.add(f.id)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(_feedbackRepositoryProvider).tandaiDibaca(f.id);
      } catch (_) {
        return;
      }
      if (!mounted) return;
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) ref.invalidate(feedbackListProvider);
      });
    });
  }

  Future<void> _balas(FeedbackModel f) async {
    final teks = _ctrl(f.id).text.trim();
    if (teks.isEmpty) {
      _toast('Balasan tidak boleh kosong.', error: true);
      return;
    }

    setState(() => _sending.add(f.id));
    try {
      await ref.read(_feedbackRepositoryProvider).balas(f.id, teks);
      if (!mounted) return;
      _ctrl(f.id).clear();

      ref.invalidate(feedbackListProvider);
      await ref.read(feedbackListProvider.future);
      _toast('Balasan terkirim.');
    } catch (e) {
      if (!mounted) return;
      _toast(_pesanError(e, fallback: 'Gagal mengirim balasan.'), error: true);
      ref.invalidate(feedbackListProvider);
    } finally {
      if (mounted) setState(() => _sending.remove(f.id));
    }
  }

  Future<void> _segarkan() async {
    ref.invalidate(feedbackListProvider);
    try {
      await ref.read(feedbackListProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);
    final semua = feedbackAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <FeedbackModel>[],
    );
    final jumlahAi = semua.where((f) => f.senderType == SenderType.ai).length;
    final jumlahCoach = semua.length - jumlahAi;

    final pertamaCoach = semua.where((f) => f.senderType == SenderType.coach);
    final labelCoach = pertamaCoach.isEmpty
        ? 'Coach'
        : pertamaCoach.first.senderName.split(' ').take(2).join(' ');

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: BugarinHeader(subtitle: 'Feedback'),
            ),
            const SizedBox(height: 24),

            // TITLE AREA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evaluasi & Saran',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Umpan balik personalisasi AI & arahan Coach',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FILTER CHIPS (jumlah dihitung dari data)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(0, 'Semua (${semua.length})'),
                  const SizedBox(width: 10),
                  _buildFilterChip(1, 'AI Insight ($jumlahAi)'),
                  const SizedBox(width: 10),
                  _buildFilterChip(2, '$labelCoach ($jumlahCoach)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: feedbackAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _oranye)),
                error: (err, _) => _buildError(err),
                data: (feedbacks) {
                  final filteredList = feedbacks.where((f) {
                    if (_selectedFilter == 1) return f.senderType == SenderType.ai;
                    if (_selectedFilter == 2) return f.senderType == SenderType.coach;
                    return true;
                  }).toList();

                  return RefreshIndicator(
                    color: _oranye,
                    onRefresh: _segarkan,
                    child: filteredList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Belum ada feedback.',
                                  style: TextStyle(color: context.textMuted, fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              _tandaiDibacaBilaPerlu(item);
                              return item.senderType == SenderType.ai
                                  ? _buildAICard(item)
                                  : _buildCoachCard(item);
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              _pesanError(err, fallback: 'Gagal memuat feedback.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(feedbackListProvider),
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

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _oranye : context.surfaceInner,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _oranye : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _titikBaru(FeedbackModel item) {
    if (item.dibaca) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: const BoxDecoration(color: _oranye, shape: BoxShape.circle),
    );
  }

  Widget _buildAICard(FeedbackModel item) {
    final adaStat = (item.caloryStat?.isNotEmpty ?? false) || (item.sleepStat?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.dibaca ? context.border : _oranye.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: _oranye, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.senderName,
                          style: const TextStyle(
                            color: _oranye,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(item.senderRole,
                            style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _titikBaru(item),
                  Text(_formatWaktu(item.createdAt),
                      style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          if (adaStat) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.caloryStat?.isNotEmpty ?? false)
                  _buildStatChip(Icons.local_fire_department, item.caloryStat!, isRed: true),
                if (item.sleepStat?.isNotEmpty ?? false)
                  _buildStatChip(Icons.dark_mode_outlined, item.sleepStat!, isRed: false),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            item.content,
            style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, {required bool isRed}) {
    const merahStat = Color(0xFFFF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRed ? merahStat.withValues(alpha: 0.12) : context.surfaceInner,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isRed ? merahStat : context.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isRed ? merahStat : context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPt(FeedbackModel item) {
    final url = _resolveMediaUrl(item.senderPhotoUrl);
    final inisial = item.senderName.replaceFirst('Coach ', '').trim();
    final huruf = inisial.isEmpty ? '?' : inisial[0].toUpperCase();

    Widget fallback() => Container(
          color: context.surfaceInner,
          alignment: Alignment.center,
          child: Text(huruf,
              style: const TextStyle(color: _oranye, fontWeight: FontWeight.bold, fontSize: 16)),
        );

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _oranye, width: 1.5),
      ),
      child: ClipOval(
        child: url == null
            ? fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
                loadingBuilder: (_, child, progress) => progress == null ? child : fallback(),
              ),
      ),
    );
  }

  Widget _buildCoachCard(FeedbackModel item) {
    final status = item.replyStatus;
    final mengirim = _sending.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.dibaca ? context.border : _oranye.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildFotoPt(item),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.senderName,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _titikBaru(item),
                      Text(_formatWaktu(item.createdAt),
                          style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                  if (status == ReplyStatus.waiting) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _oranye,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Menunggu\nBalasan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (item.coachTag != null && item.coachTag!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _oranye,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.coachTag!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            item.content,
            style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5),
          ),

          // Sudah dibalas: tampil read-only (balasan hanya boleh 1x).
          if (status == ReplyStatus.replied) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balasan Anda',
                          style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      if (item.replyTime != null)
                        Text('Dibalas ${_formatWaktu(item.replyTime!)}',
                            style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.userReply!,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == ReplyStatus.waiting) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl(item.id),
                      enabled: !mengirim,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ketik balasan Anda...',
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: mengirim ? null : () => _balas(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _oranye,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _oranye.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    child: mengirim
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Balas',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}