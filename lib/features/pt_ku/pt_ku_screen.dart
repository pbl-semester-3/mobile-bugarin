import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_provider.dart';

// ============================================================================
// KONFIGURASI
// ============================================================================

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// Hanya berlaku saat _kPakaiMock = true. Untuk menguji tiap kondisi layar:
///  'tidak_ada'    -> belum ada request, daftar rekomendasi tampil
///  'pending'      -> menunggu konfirmasi PT
///  'ditolak'      -> request ditolak + alasan, daftar rekomendasi tampil lagi
///  'diterima'     -> PT aktif
///  'profil_kosong'-> "Lengkapi profil dulu"
const String _kMockSkenario = 'tidak_ada';

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// SESUAIKAN dengan key JWT yang dipakai halaman login.
const String _kTokenKey = 'auth_token';

/// SESUAIKAN dengan route onboarding di router.
const String _kRuteOnboarding = '/onboarding';

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);

// Jika nama key dari backend berbeda, cukup ubah di fromJson.


class TrainerModel {
  final dynamic rawId;
  final String nama;
  final int pengalamanTahun;
  final String lokasiGym;
  final String avatarUrl;
  final String spesialisasi;

  const TrainerModel({
    required this.rawId,
    required this.nama,
    this.pengalamanTahun = 0,
    this.lokasiGym = '',
    this.avatarUrl = '',
    this.spesialisasi = '',
  });

  String get id => rawId.toString();
  String get ringkasan => [
        if (spesialisasi.isNotEmpty) spesialisasi,
        if (pengalamanTahun > 0) '$pengalamanTahun thn exp',
        if (lokasiGym.isNotEmpty) lokasiGym,
      ].join(' • ');

  String get detail => [
        if (pengalamanTahun > 0) '$pengalamanTahun thn exp',
        if (lokasiGym.isNotEmpty) lokasiGym,
      ].join(' • ');

  factory TrainerModel.fromJson(Map<String, dynamic> j) {
    return TrainerModel(
      rawId: j['id'] ?? j['pt_id'],
      nama: (j['nama'] ?? '').toString(),
      pengalamanTahun: int.tryParse('${j['pengalaman_tahun'] ?? 0}') ?? 0,
      lokasiGym: (j['tempat_gym'] ?? j['lokasi_gym'] ?? '').toString(),
      avatarUrl: (j['foto_url'] ?? j['avatar_url'] ?? j['foto_profil'] ?? '').toString(),
      spesialisasi: (j['spesialisasi'] ?? '').toString(),
    );
  }
}

class _PairingRequest {
  final String status;
  final String? alasanPenolakan;
  final TrainerModel? pt;

  const _PairingRequest({required this.status, this.alasanPenolakan, this.pt});

  bool get pending => status == 'pending';
  bool get ditolak => status == 'ditolak' || status == 'rejected';
  bool get diterima => status == 'diterima' || status == 'accepted' || status == 'aktif';

  factory _PairingRequest.fromJson(Map<String, dynamic> j) {
    final rawPt = j['pt'];
    return _PairingRequest(
      status: (j['status'] ?? '').toString().toLowerCase(),
      alasanPenolakan: j['alasan_penolakan']?.toString(),
      pt: rawPt is Map<String, dynamic> ? TrainerModel.fromJson(rawPt) : null,
    );
  }
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

Map<String, dynamic> _unwrapMap(dynamic body) {
  if (body is Map<String, dynamic>) {
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
  return <String, dynamic>{};
}

const List<TrainerModel> _daftarContoh = [
  TrainerModel(
    rawId: 1,
    nama: 'Sarah Jenkins',
    pengalamanTahun: 7,
    lokasiGym: 'FitZone Senopati',
    avatarUrl: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=150',
    spesialisasi: 'Hipertrofi & Strength',
  ),
  TrainerModel(
    rawId: 2,
    nama: 'Elena Vance',
    pengalamanTahun: 5,
    lokasiGym: 'FitZone Dharmawangsa',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    spesialisasi: 'Pilates & Core Stability',
  ),
  TrainerModel(
    rawId: 3,
    nama: 'Dian Pratama',
    pengalamanTahun: 6,
    lokasiGym: 'FitZone Kuningan',
    avatarUrl: 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=150',
    spesialisasi: 'Strength & Conditioning',
  ),
  TrainerModel(
    rawId: 4,
    nama: 'Alex Sander',
    pengalamanTahun: 9,
    lokasiGym: 'FitZone Sudirman',
    avatarUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=150',
    spesialisasi: 'Fat Loss & Transformation',
  ),
];

class _PtRepository {
  static _PairingRequest? _mockRequest = _awalMock();

  static _PairingRequest? _awalMock() {
    final pt = _daftarContoh.first;
    switch (_kMockSkenario) {
      case 'pending':
        return _PairingRequest(status: 'pending', pt: pt);
      case 'ditolak':
        return _PairingRequest(
          status: 'ditolak',
          alasanPenolakan: 'Jadwal Coach sedang penuh untuk bulan ini.',
          pt: pt,
        );
      case 'diterima':
        return _PairingRequest(status: 'diterima', pt: pt);
      default:
        return null;
    }
  }

  Future<void> _tunda([int ms = 500]) => Future.delayed(Duration(milliseconds: ms));

  Future<String?> ambilTujuan() async {
    if (_kPakaiMock) {
      await _tunda();
      return _kMockSkenario == 'profil_kosong' ? null : 'turun_bb';
    }
    final res = await _buatDio().get('/klien/profile');
    final map = _unwrapMap(res.data);
    final cycle = map['cycle_aktif'] ?? map['progress_cycle'] ?? map['cycle'];
    if (cycle is Map<String, dynamic>) {
      final t = cycle['tujuan']?.toString();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  Future<_PairingRequest?> ambilRequestAktif() async {
    if (_kPakaiMock) {
      await _tunda();
      return _mockRequest;
    }
    try {
      final res = await _buatDio().get('/klien/pairing-requests/current');
      final map = _unwrapMap(res.data);
      if (map.isEmpty || map['status'] == null) return null;
      return _PairingRequest.fromJson(map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<TrainerModel>> ambilRekomendasi(String tujuan) async {
    if (_kPakaiMock) {
      await _tunda();
      return _daftarContoh;
    }
    final res = await _buatDio().get('/pt/recommendations', queryParameters: {'tujuan': tujuan});
    final body = res.data;
    final list = body is List ? body : (body is Map ? body['data'] : null);
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map(TrainerModel.fromJson).toList();
  }

  /// POST /klien/pairing-requests  { "pt_id": ... }
  Future<void> kirimRequest(TrainerModel pt) async {
    if (_kPakaiMock) {
      await _tunda(800);
      _mockRequest = _PairingRequest(status: 'pending', pt: pt);
      return;
    }
    await _buatDio().post('/klien/pairing-requests', data: {'pt_id': pt.rawId});
  }
}

class PtKuScreen extends StatefulWidget {
  const PtKuScreen({super.key});

  @override
  State<PtKuScreen> createState() => PtKuScreenState();
}

class PtKuScreenState extends State<PtKuScreen> {
  final _repo = _PtRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedTrainerId = '';
  String _kueri = '';

  bool _memuat = true;
  String? _errorMuat;
  String? _tujuan;
  _PairingRequest? _request;
  List<TrainerModel> _trainers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _kueri) setState(() => _kueri = q);
    });
    _muat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _muat({bool senyap = false}) async {
    if (!senyap) {
      setState(() {
        _memuat = true;
        _errorMuat = null;
      });
    }
    try {
      final hasil = await Future.wait<Object?>([
        _repo.ambilTujuan(),
        _repo.ambilRequestAktif(),
      ]);
      final tujuan = hasil[0] as String?;
      final request = hasil[1] as _PairingRequest?;

      var daftar = <TrainerModel>[];
      if (tujuan != null && (request == null || request.ditolak)) {
        daftar = await _repo.ambilRekomendasi(tujuan);
      }

      if (!mounted) return;
      setState(() {
        _tujuan = tujuan;
        _request = request;
        _trainers = daftar;
        _errorMuat = null;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMuat = _pesanError(e, fallback: 'Gagal memuat data PT.');
        _memuat = false;
      });
    }
  }

  List<TrainerModel> get _terfilter {
    if (_kueri.isEmpty) return _trainers;
    return _trainers.where((t) {
      return t.nama.toLowerCase().contains(_kueri) ||
          t.spesialisasi.toLowerCase().contains(_kueri) ||
          t.lokasiGym.toLowerCase().contains(_kueri);
    }).toList();
  }

  void _toast(String pesan, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _merah : Colors.green.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(pesan),
        ),
      );
  }

  Future<void> _pilih(TrainerModel trainer) async {
    setState(() => _selectedTrainerId = trainer.id);

    final berhasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KonfirmasiDialog(
        trainer: trainer,
        onKirim: () => _repo.kirimRequest(trainer),
      ),
    );

    if (!mounted) return;
    setState(() => _selectedTrainerId = '');

    if (berhasil == true) {
      _toast('Request terkirim! Menunggu konfirmasi Coach ${trainer.nama}.');
      await _muat(senyap: true);
    }
  }

  Future<void> _lengkapiProfil() async {
    await context.push(_kRuteOnboarding);
    if (mounted) _muat();
  }

  @override
  Widget build(BuildContext context) {
    final r = _request;
    String judul = 'Pilih Personal Trainer';
    String subjudul = 'Coach terakreditasi untuk siklus targetmu';
    if (!_memuat && _errorMuat == null && _tujuan != null && r != null) {
      if (r.diterima) {
        judul = 'PT ku';
        subjudul = 'Personal trainer Anda saat ini';
      } else if (r.pending) {
        judul = 'PT ku';
        subjudul = 'Menunggu konfirmasi dari PT';
      }
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _oranye,
          onRefresh: () => _muat(senyap: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(judul, subjudul),
                const SizedBox(height: 18),
                _buildIsi(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String judul, String subjudul) {
    final bisaKembali = Navigator.of(context).canPop();
    return Row(
      children: [
        if (bisaKembali) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.surfaceInner,
                shape: BoxShape.circle,
                border: Border.all(color: context.border),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: context.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subjudul,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIsi() {
    if (_memuat) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: _oranye, strokeWidth: 2.2)),
      );
    }
    if (_errorMuat != null) return _buildError();
    if (_tujuan == null) return _buildProfilKosong();

    final r = _request;
    if (r != null && r.pending) return _buildStatusPending(r);
    if (r != null && r.diterima) return _buildPtAktif(r);

    return _buildDaftar(r);
  }

  Widget _kotakTengah({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Widget _buildError() {
    return _kotakTengah(
      children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
        const SizedBox(height: 12),
        Text(
          _errorMuat!,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _muat,
          style: ElevatedButton.styleFrom(
            backgroundColor: _oranye,
            foregroundColor: Colors.white,
          ),
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildProfilKosong() {
    return _kotakTengah(
      children: [
        const Icon(Icons.assignment_ind_outlined, size: 48, color: _oranye),
        const SizedBox(height: 14),
        Text(
          'Lengkapi profil dulu',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Isi profil dan target Anda agar kami dapat\nmerekomendasikan PT yang sesuai.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 220,
          height: 46,
          child: ElevatedButton(
            onPressed: _lengkapiProfil,
            style: ElevatedButton.styleFrom(
              backgroundColor: _oranye,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Lengkapi Profil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _kartu({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? context.border, width: 1.2),
      ),
      child: child,
    );
  }

  Widget _buildStatusPending(_PairingRequest r) {
    final pt = r.pt;
    return _kartu(
      borderColor: const Color(0x4DFF5520),
      child: Column(
        children: [
          if (pt != null) ...[
            _Avatar(url: pt.avatarUrl, nama: pt.nama, size: 72),
            const SizedBox(height: 12),
            Text(
              'Coach ${pt.nama}',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pt.ringkasan.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pt.ringkasan,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1AFF5520),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 16, color: _oranye),
                SizedBox(width: 8),
                Text(
                  'Menunggu konfirmasi PT',
                  style: TextStyle(color: _oranye, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Permintaan Anda sudah terkirim. Tarik layar ke bawah untuk memperbarui status.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPtAktif(_PairingRequest r) {
    final pt = r.pt;
    if (pt == null) {
      return _kartu(
        child: Text(
          'Anda sudah terhubung dengan PT.',
          style: TextStyle(color: context.textPrimary, fontSize: 14),
        ),
      );
    }
    return _kartu(
      borderColor: _oranye,
      child: Row(
        children: [
          _Avatar(url: pt.avatarUrl, nama: pt.nama, size: 60, aktif: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach ${pt.nama}',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pt.spesialisasi.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(pt.spesialisasi,
                      style: TextStyle(color: context.textSecondary, fontSize: 12)),
                ],
                if (pt.detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(pt.detail, style: TextStyle(color: context.textMuted, fontSize: 11)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF5520),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PT AKTIF',
                    style: TextStyle(
                      color: _oranye,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerDitolak(_PairingRequest r) {
    final nama = r.pt?.nama;
    final alasan = r.alasanPenolakan;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _merah.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _merah, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama == null
                      ? 'Permintaan Anda ditolak'
                      : 'Permintaan ke Coach $nama ditolak',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (alasan != null && alasan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: $alasan',
                    style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Silakan pilih PT lain di bawah ini.',
                  style: TextStyle(color: context.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftar(_PairingRequest? r) {
    final daftar = _terfilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r != null && r.ditolak) _buildBannerDitolak(r),

        // SEARCH BAR
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.textMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, spesialisasi, atau gym...',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Tersedia ${daftar.length} Personal Trainer',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (daftar.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                _trainers.isEmpty
                    ? 'Belum ada rekomendasi PT untuk target Anda.'
                    : 'Tidak ada PT yang cocok dengan pencarian.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          for (final trainer in daftar) _buildTrainerCard(trainer),
      ],
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer) {
    final isSelected = trainer.id == _selectedTrainerId;

    return GestureDetector(
      onTap: () => _pilih(trainer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _oranye : context.border,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            _Avatar(url: trainer.avatarUrl, nama: trainer.nama, size: 48, aktif: isSelected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer.nama,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trainer.spesialisasi.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      trainer.spesialisasi,
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    ),
                  ],
                  if (trainer.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      trainer.detail,
                      style: TextStyle(color: context.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? _oranye : context.surfaceInner,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : context.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pilih',
                    style: TextStyle(
                      color: isSelected ? Colors.white : context.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : context.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.nama, required this.size, this.aktif = false});

  final String url;
  final String nama;
  final double size;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveMediaUrl(url);
    final inisial = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();

    Widget fallback() => Container(
          color: context.surfaceInner,
          alignment: Alignment.center,
          child: Text(
            inisial,
            style: TextStyle(
              color: _oranye,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: aktif ? _oranye : context.border, width: aktif ? 2 : 1.5),
      ),
      child: ClipOval(
        child: resolved == null
            ? fallback()
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
                loadingBuilder: (_, child, progress) => progress == null ? child : fallback(),
              ),
      ),
    );
  }
}

class _KonfirmasiDialog extends StatefulWidget {
  const _KonfirmasiDialog({required this.trainer, required this.onKirim});

  final TrainerModel trainer;
  final Future<void> Function() onKirim;

  @override
  State<_KonfirmasiDialog> createState() => _KonfirmasiDialogState();
}

class _KonfirmasiDialogState extends State<_KonfirmasiDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _kirim() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onKirim();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _pesanError(e, fallback: 'Gagal mengirim permintaan. Silakan coba lagi.');
      });
    }
  }

  void _tutup() {
    if (!_loading) Navigator.pop(context, false);
  }

  Widget _barisFitur(IconData icon, String teks, {String? sorot}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _oranye),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: teks),
                if (sorot != null)
                  TextSpan(
                    text: sorot,
                    style: const TextStyle(color: _oranye, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            style: TextStyle(color: context.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    final namaDepan = trainer.nama.split(' ').first.toUpperCase();

    return Dialog(
      backgroundColor: context.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _tutup,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                  ),
                ),
              ),

              // AVATAR + GLOW
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x4DFF5520), blurRadius: 24, spreadRadius: 4),
                  ],
                ),
                child: _Avatar(url: trainer.avatarUrl, nama: trainer.nama, size: 80, aktif: true),
              ),
              const SizedBox(height: 16),

              Text(
                'Coach ${trainer.nama}',
                style: const TextStyle(
                  color: _oranye,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trainer.ringkasan.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  trainer.ringkasan,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
              const SizedBox(height: 28),

              Text(
                'Yakin Ingin Memilih PT Ini?',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Anda akan terhubung langsung dengan Coach ${trainer.nama} untuk menyusun program latihan dan panduan transformasi kebugaran Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    _barisFitur(Icons.calendar_today_rounded, 'Sesi Aktif: ',
                        sorot: '12 Sesi Pertemuan'),
                    const SizedBox(height: 16),
                    _barisFitur(Icons.schedule_rounded, 'Jadwal Fleksibel & Booking Mandiri'),
                    const SizedBox(height: 16),
                    _barisFitur(Icons.check_circle_outline_rounded,
                        'Konsultasi Nutrisi & Panduan Pola Makan'),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _merah, fontSize: 12),
                ),
              ],
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _kirim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _oranye,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _oranye.withAlpha(150),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'YA, PILIH COACH $namaDepan',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _tutup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Batalkan',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}