import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

// ===================== KONFIGURASI & KLIEN API =====================

/// SESUAIKAN dengan alamat backend.
/// Emulator Android -> 10.0.2.2 mengarah ke localhost komputer.
/// Perangkat fisik -> pakai IP LAN komputer atau domain server.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// MODE DATA CONTOH.
/// true  = tidak memanggil backend, memakai data dummy (untuk melihat/menguji tampilan).
/// false = memanggil backend sungguhan. UBAH KE false SAAT BACKEND SUDAH SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan key yang dipakai LoginScreen saat menyimpan JWT.
const String _kTokenKey = 'auth_token';

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final _dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(_secureStorageProvider);

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
});

Map<String, dynamic> _unwrapMap(dynamic body) {
  if (body is Map<String, dynamic>) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }
  return <String, dynamic>{};
}

String? _resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = Uri.parse(_kBaseUrl).origin;
  return url.startsWith('/') ? '$origin$url' : '$origin/$url';
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

double? _toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

String _alergiKeString(dynamic v) {
  if (v == null) return '';
  if (v is List) return v.join(', ');
  return v.toString();
}

String? _normalJenisKelamin(dynamic v) {
  final s = (v ?? '').toString().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  if (s == 'laki_laki' || s == 'l' || s == 'male') return 'laki_laki';
  if (s == 'perempuan' || s == 'p' || s == 'female') return 'perempuan';
  return null;
}

const List<String> _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

class _ProgressCycle {
  const _ProgressCycle({
    required this.id,
    required this.tujuan,
    required this.bbAwal,
    required this.bbTujuan,
    required this.durasiHari,
    required this.targetKalori,
    required this.tanggalMulai,
    required this.status,
  });

  final String id;
  final String tujuan; 
  final double bbAwal;
  final double bbTujuan;
  final int durasiHari;
  final double? targetKalori;
  final DateTime tanggalMulai;
  final String status; 

  bool get selesai => status == 'selesai';

  String get labelTujuan {
    switch (tujuan) {
      case 'turun_bb':
        return 'Turun BB';
      case 'naik_bb':
        return 'Naik BB';
      default:
        return '-';
    }
  }

  int get hariKe {
    final d = DateTime.now().difference(tanggalMulai).inDays + 1;
    if (d < 1) return 1;
    if (durasiHari > 0 && d > durasiHari) return durasiHari;
    return d;
  }

  factory _ProgressCycle.fromJson(Map<String, dynamic> j) {
    return _ProgressCycle(
      id: j['id'].toString(),
      tujuan: (j['tujuan'] ?? '').toString(),
      bbAwal: _toDouble(j['bb_awal_kg']) ?? 0,
      bbTujuan: _toDouble(j['bb_tujuan_kg']) ?? 0,
      durasiHari: _toInt(j['durasi_hari']) ?? 0,
      targetKalori: _toDouble(j['target_kalori_per_hari']),
      tanggalMulai:
          DateTime.tryParse((j['tanggal_mulai'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      status: (j['status'] ?? '').toString(),
    );
  }
}

/// Respons GET /klien/profile.
/// Jika nama key dari backend berbeda, cukup ubah di factory ini.
class _KlienProfile {
  const _KlienProfile({
    required this.nama,
    required this.email,
    required this.username,
    required this.usia,
    required this.jenisKelamin,
    required this.alergi,
    required this.tinggiBadan,
    required this.fotoUrl,
    required this.bbSekarang,
    required this.tema,
    required this.dibuatPada,
    required this.cycle,
  });

  final String nama;
  final String email;
  final String username;
  final int? usia;
  final String? jenisKelamin; 
  final String alergi;
  final double? tinggiBadan;
  final String? fotoUrl;
  final double? bbSekarang; 
  final String? tema; 
  final DateTime? dibuatPada;
  final _ProgressCycle? cycle;

  String get memberSejak {
    final d = dibuatPada;
    if (d == null) return '';
    return 'Member Sejak ${_bulan[d.month - 1]} ${d.year}';
  }

  factory _KlienProfile.fromJson(Map<String, dynamic> j) {
    final rawCycle = j['cycle_aktif'] ?? j['progress_cycle'] ?? j['cycle'];
    return _KlienProfile(
      nama: (j['nama'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      username: (j['username'] ?? '').toString(),
      usia: _toInt(j['usia']),
      jenisKelamin: _normalJenisKelamin(j['jenis_kelamin']),
      alergi: _alergiKeString(j['alergi'] ?? j['alergi_makanan']),
      tinggiBadan: _toDouble(j['tinggi_badan']),
      fotoUrl: (j['foto_url'] ?? j['foto_profil'])?.toString(),
      bbSekarang: _toDouble(j['bb_sekarang'] ?? j['bb_sekarang_kg']),
      tema: (j['theme'] ?? j['tema'])?.toString(),
      dibuatPada: DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal(),
      cycle: rawCycle is Map<String, dynamic> ? _ProgressCycle.fromJson(rawCycle) : null,
    );
  }
}

class _ProfilRepository {
  _ProfilRepository(this._dio);

  final Dio _dio;

  static final Map<String, dynamic> _mock = {
    'nama': 'Maya Ayuningsih',
    'email': 'maya@bugarin.id',
    'username': 'mayaayu',
    'usia': 26,
    'jenis_kelamin': 'perempuan',
    'alergi': 'Laktosa, Kacang Tanah',
    'tinggi_badan': 168,
    'foto_url': null,
    'bb_sekarang': 72.0,
    'created_at': '2024-01-15T00:00:00Z',
    'cycle_aktif': {
      'id': 1,
      'tujuan': 'turun_bb',
      'bb_awal_kg': 78.5,
      'bb_tujuan_kg': 67.0,
      'durasi_hari': 60,
      'target_kalori_per_hari': 1980,
      'tanggal_mulai':
          DateTime.now().subtract(const Duration(days: 41)).toIso8601String(),
      'status': 'aktif',
    },
  };

  Future<void> _tunda() => Future.delayed(const Duration(milliseconds: 500));

  Future<_KlienProfile> ambilProfil() async {
    if (_kPakaiMock) {
      await _tunda();
      return _KlienProfile.fromJson(Map<String, dynamic>.from(_mock));
    }
    final res = await _dio.get('/klien/profile');
    return _KlienProfile.fromJson(_unwrapMap(res.data));
  }

  Future<void> perbaruiProfil(Map<String, dynamic> body) async {
    if (_kPakaiMock) {
      await _tunda();
      _mock.addAll(body);
      return;
    }
    await _dio.put('/klien/profile', data: body);
  }

  Future<void> catatBeratBadan(double beratKg) async {
    if (_kPakaiMock) {
      await _tunda();
      _mock['bb_sekarang'] = beratKg;
      final cycle = Map<String, dynamic>.from(_mock['cycle_aktif'] as Map);
      final awal = (cycle['bb_awal_kg'] as num).toDouble();
      final tujuan = (cycle['bb_tujuan_kg'] as num).toDouble();
      final tercapai = tujuan < awal ? beratKg <= tujuan : beratKg >= tujuan;
      if (tercapai) cycle['status'] = 'selesai'; // untuk menguji banner target
      _mock['cycle_aktif'] = cycle;
      return;
    }
    await _dio.post('/klien/weight-logs', data: {'berat_kg': beratKg});
  }

  Future<void> ubahSandi({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasi,
  }) async {
    if (_kPakaiMock) {
      await _tunda();
      return;
    }
    await _dio.put('/klien/password', data: {
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
      'konfirmasi_password': konfirmasi,
    });
  }

  Future<void> ubahTema(String tema) async {
    if (_kPakaiMock) return;
    await _dio.put('/klien/theme', data: {'theme': tema});
  }

  Future<String?> unggahFoto(String path) async {
    if (_kPakaiMock) {
      await _tunda();
      _mock['foto_url'] = 'mock:$path';
      return 'mock:$path';
    }
    final namaFile = path.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      'foto': await MultipartFile.fromFile(path, filename: namaFile),
    });
    final res = await _dio.post('/klien/profile/photo', data: form);
    return _unwrapMap(res.data)['foto_url']?.toString();
  }
}

final _profilRepositoryProvider = Provider<_ProfilRepository>(
  (ref) => _ProfilRepository(ref.watch(_dioProvider)),
);


class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
          border: InputBorder.none,
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final ImagePicker _picker = ImagePicker();

  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _usiaCtrl = TextEditingController();
  final _alergiCtrl = TextEditingController();
  final _tinggiCtrl = TextEditingController();
  final _bbCtrl = TextEditingController();

  _KlienProfile? _profil;
  bool _memuat = true;
  String? _errorMuat;
  String? _jenisKelamin;

  XFile? _fotoLokal;
  int _fotoVersi = 0;

  bool _unggahFoto = false;
  bool _simpanDiri = false;
  bool _simpanTinggi = false;
  bool _simpanBB = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _usiaCtrl.dispose();
    _alergiCtrl.dispose();
    _tinggiCtrl.dispose();
    _bbCtrl.dispose();
    super.dispose();
  }


  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _errorMuat = null;
    });
    try {
      final p = await ref.read(_profilRepositoryProvider).ambilProfil();
      if (!mounted) return;

      _namaCtrl.text = p.nama;
      _emailCtrl.text = p.email;
      _usernameCtrl.text = p.username;
      _usiaCtrl.text = p.usia?.toString() ?? '';
      _alergiCtrl.text = p.alergi;
      _tinggiCtrl.text = p.tinggiBadan == null ? '' : _formatAngka(p.tinggiBadan!);

      setState(() {
        _profil = p;
        _jenisKelamin = p.jenisKelamin;
        _memuat = false;
      });
      _sinkronTemaDariServer(p.tema);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMuat = _pesanError(e, fallback: 'Gagal memuat profil.');
        _memuat = false;
      });
    }
  }

  Future<void> _segarkan() async {
    try {
      final p = await ref.read(_profilRepositoryProvider).ambilProfil();
      if (mounted) setState(() => _profil = p);
    } catch (_) {}
  }

  void _sinkronTemaDariServer(String? tema) {
    final sedangGelap = ref.read(themeModeProvider) == ThemeMode.dark;
    final notifier = ref.read(themeModeProvider.notifier);
    if (tema == 'dark' && !sedangGelap) {
      notifier.setDark();
    } else if (tema == 'light' && sedangGelap) {
      notifier.setLight();
    }
  }

  String _formatAngka(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

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


  Future<void> _gantiFoto() async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah Foto Profil',
                style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_outlined, color: _oranye),
                title: Text('Ambil dari kamera', style: TextStyle(color: ctx.textPrimary, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined, color: _oranye),
                title: Text('Pilih dari galeri', style: TextStyle(color: ctx.textPrimary, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (sumber == null) return;

    XFile? hasil;
    try {
      hasil = await _picker.pickImage(
        source: sumber,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } on PlatformException {
      _toast('Akses kamera/galeri ditolak. Aktifkan izin di pengaturan perangkat.', error: true);
      return;
    }
    if (hasil == null) return;
    final XFile dipilih = hasil;

    final ukuran = await dipilih.length();
    if (ukuran > 5 * 1024 * 1024) {
      _toast('Ukuran foto maksimal 5 MB.', error: true);
      return;
    }

    if (sumber == ImageSource.camera) {
      await _simpanKeGaleri(dipilih.path);
    }

    setState(() {
      _fotoLokal = dipilih;
      _unggahFoto = true;
    });

    try {
      await ref.read(_profilRepositoryProvider).unggahFoto(dipilih.path);
      _fotoVersi++;
      await _segarkan();
      if (!mounted) return;
      setState(() => _fotoLokal = null);
      _toast('Foto profil berhasil diperbarui.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _fotoLokal = null);
      _toast(_pesanError(e, fallback: 'Gagal mengunggah foto.'), error: true);
    } finally {
      if (mounted) setState(() => _unggahFoto = false);
    }
  }

  Future<void> _simpanKeGaleri(String path) async {
    if (kIsWeb) return; // penyimpanan ke galeri hanya untuk Android/iOS
    try {
      final punyaAkses = await Gal.hasAccess() || await Gal.requestAccess();
      if (punyaAkses) {
        await Gal.putImage(path, album: 'Bugarin');
      }
    } catch (_) {
      // Izin ditolak atau gagal menyimpan: abaikan, unggahan tetap dilanjutkan.
    }
  }

  ImageProvider _imageDariPath(String path) =>
      kIsWeb ? NetworkImage(path) : FileImage(File(path));

  ImageProvider? _fotoProvider() {
    final lokal = _fotoLokal;
    if (lokal != null) return _imageDariPath(lokal.path);
    final raw = _profil?.fotoUrl;
    if (raw != null && raw.startsWith('mock:')) return _imageDariPath(raw.substring(5));
    final url = _resolveMediaUrl(raw);
    if (url == null) return null;
    if (_fotoVersi == 0) return NetworkImage(url);
    return NetworkImage('$url${url.contains('?') ? '&' : '?'}v=$_fotoVersi');
  }


  Future<void> _simpanInformasiDiri() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final usia = int.tryParse(_usiaCtrl.text.trim());

    if (nama.isEmpty || username.isEmpty) {
      _toast('Nama dan username wajib diisi.', error: true);
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _toast('Format email tidak valid.', error: true);
      return;
    }
    if (usia == null || usia < 10 || usia > 100) {
      _toast('Usia tidak valid.', error: true);
      return;
    }

    setState(() => _simpanDiri = true);
    try {
      await ref.read(_profilRepositoryProvider).perbaruiProfil({
        'nama': nama,
        'email': email,
        'username': username,
        'usia': usia,
        if (_jenisKelamin != null) 'jenis_kelamin': _jenisKelamin,
        'alergi': _alergiCtrl.text.trim(),
      });
      await _segarkan();
      _toast('Informasi diri berhasil diperbarui.');
    } catch (e) {
      _toast(_pesanError(e, fallback: 'Gagal menyimpan informasi diri.'), error: true);
    } finally {
      if (mounted) setState(() => _simpanDiri = false);
    }
  }

  Future<void> _simpanTinggiBadan() async {
    final tinggi = double.tryParse(_tinggiCtrl.text.trim().replaceAll(',', '.'));
    if (tinggi == null || tinggi < 100 || tinggi > 250) {
      _toast('Tinggi badan harus antara 100 dan 250 cm.', error: true);
      return;
    }

    setState(() => _simpanTinggi = true);
    try {
      await ref.read(_profilRepositoryProvider).perbaruiProfil({'tinggi_badan': tinggi});
      await _segarkan();
      _toast('Tinggi badan berhasil diperbarui.');
    } catch (e) {
      _toast(_pesanError(e, fallback: 'Gagal menyimpan tinggi badan.'), error: true);
    } finally {
      if (mounted) setState(() => _simpanTinggi = false);
    }
  }

  Future<void> _simpanBeratBadan() async {
    final bb = double.tryParse(_bbCtrl.text.trim().replaceAll(',', '.'));
    if (bb == null || bb <= 30 || bb >= 250) {
      _toast('Masukkan berat badan yang valid (30 - 250 kg).', error: true);
      return;
    }

    setState(() => _simpanBB = true);
    try {
      await ref.read(_profilRepositoryProvider).catatBeratBadan(bb);
      _bbCtrl.clear();
      await _segarkan(); // cycle bisa berubah menjadi 'selesai' bila goal tercapai
      _toast('Berat badan berhasil dicatat: ${bb.toStringAsFixed(1)} kg');
    } catch (e) {
      _toast(_pesanError(e, fallback: 'Gagal mencatat berat badan.'), error: true);
    } finally {
      if (mounted) setState(() => _simpanBB = false);
    }
  }

  Future<void> _gantiTema(bool gelap) async {
    final notifier = ref.read(themeModeProvider.notifier);
    if (gelap) {
      notifier.setDark();
    } else {
      notifier.setLight();
    }
    try {
      await ref.read(_profilRepositoryProvider).ubahTema(gelap ? 'dark' : 'light');
    } catch (_) {
      _toast('Tema diterapkan, tetapi belum tersimpan di server.', error: true);
    }
  }

  Future<void> _tampilkanUbahSandi() async {
    final berhasil = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UbahSandiSheet(),
    );
    if (berhasil == true) _toast('Kata sandi berhasil diubah.');
  }

  Future<void> _mulaiTargetBaru() async {
    await context.push('/onboarding');
    if (mounted) _segarkan();
  }

  Future<void> _keluarSesi() async {
    try {
      if (!_kPakaiMock) await ref.read(_dioProvider).post('/auth/logout');
    } catch (_) {
      // Sesi lokal tetap dihapus walau server tidak terjangkau.
    }
    await ref.read(_secureStorageProvider).deleteAll();
  }

  Future<void> _logout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.border),
        ),
        title: Text(
          'Keluar dari Akun',
          style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun dan kembali ke halaman awal?',
          style: TextStyle(color: ctx.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: ctx.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _merah,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await _keluarSesi();
    if (!mounted) return;
    context.go('/welcome');
  }

  // ---------------------------------------------------------------- BUILD

  @override
  Widget build(BuildContext context) {
    if (_memuat) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator(color: _oranye)),
      );
    }

    final p = _profil;
    if (p == null) {
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    _errorMuat ?? 'Gagal memuat profil.',
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
              ),
            ),
          ),
        ),
      );
    }

    final c = p.cycle;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _oranye,
          onRefresh: _segarkan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BugarinHeader(
                  subtitle: 'Profile',
                  showBackButton: true,
                  showProfileAvatar: false,
                ),
                const SizedBox(height: 18),
                _buildHeaderCard(p),
                const SizedBox(height: 14),
                if (c != null && c.selesai) ...[
                  _buildBannerTargetBaru(),
                  const SizedBox(height: 16),
                ],
                if (c != null) ...[
                  _buildProgressCard(p, c),
                  const SizedBox(height: 16),
                  _buildInfoSiklus(c),
                  const SizedBox(height: 18),
                ],
                _buildDetailPenting(),
                const SizedBox(height: 18),
                _buildInformasiDiri(),
                const SizedBox(height: 18),
                _buildPengaturan(isDark),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: _merah, size: 18),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(color: _merah, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2E1717) : const Color(0xFFFFCDD2),
                      ),
                      backgroundColor: isDark ? const Color(0xFF1A0F0F) : const Color(0xFFFFEBEE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _card({
    required Widget child,
    double radius = 24,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.border, width: 1.2),
      ),
      child: child,
    );
  }

  Widget _label(String teks) {
    return Text(
      teks,
      style: TextStyle(
        color: context.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _tombolSimpan(bool loading, VoidCallback onTap) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: _oranye, strokeWidth: 2),
            )
          : const Text(
              'Simpan',
              style: TextStyle(color: _oranye, fontSize: 13, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildAvatar(_KlienProfile p) {
    final img = _fotoProvider();
    final inisial = p.nama.trim().isEmpty ? '?' : p.nama.trim()[0].toUpperCase();

    return GestureDetector(
      onTap: _unggahFoto ? null : _gantiFoto,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceInner,
                border: Border.all(color: _oranye, width: 2.2),
                image: img == null
                    ? null
                    : DecorationImage(image: img, fit: BoxFit.cover, onError: (_, __) {}),
              ),
              child: img == null
                  ? Center(
                      child: Text(
                        inisial,
                        style: const TextStyle(
                          color: _oranye,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            if (_unggahFoto)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x88000000),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _oranye,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.card, width: 2),
                ),
                child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(_KlienProfile p) {
    return _card(
      radius: 28,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          _buildAvatar(p),
          const SizedBox(height: 14),
          Text(
            p.nama,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('@${p.username}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
          if (p.memberSejak.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text(p.memberSejak, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerTargetBaru() {
    return InkWell(
      onTap: _mulaiTargetBaru,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x4DFF5520)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '🎉 Target tercapai! Mulai target baru?',
                style: TextStyle(color: _oranye, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: _oranye, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(_KlienProfile p, _ProgressCycle c) {
    final double sekarang = p.bbSekarang ?? c.bbAwal;
    final double jarak = c.bbTujuan - c.bbAwal;
    // Dihitung bertanda sehingga benar untuk Turun BB maupun Naik BB,
    // lalu di-clamp 0..100% (angka asli tetap tersimpan di backend).
    final double rasio =
        jarak == 0 ? 0.0 : ((sekarang - c.bbAwal) / jarak).clamp(0.0, 1.0).toDouble();
    final double selisih = sekarang - c.bbAwal;
    final String tanda = selisih > 0 ? '+' : '';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _oranye,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'KINI: ${sekarang.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (_, constraints) {
              final lebar = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: lebar * rasio,
                    decoration: BoxDecoration(
                      color: _oranye,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: ((lebar * rasio) - 8).clamp(0.0, lebar - 16).toDouble(),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _oranye, width: 3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BB AWAL',
                      style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('${c.bbAwal.toStringAsFixed(1)} kg',
                      style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(
                'PENCAPAIAN $tanda${selisih.toStringAsFixed(1)} KG',
                style: const TextStyle(color: _oranye, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BB TUJUAN',
                      style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('${c.bbTujuan.toStringAsFixed(1)} kg',
                      style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Target kalori, durasi, dan tujuan: read-only dari progress_cycles aktif.
  Widget _buildInfoSiklus(_ProgressCycle c) {
    final kalori = c.targetKalori == null ? '-' : '${c.targetKalori!.round()} kcal/hari';
    final double progresSiklus =
        c.durasiHari > 0 ? (c.hariKe / c.durasiHari).clamp(0.0, 1.0).toDouble() : 0.0;

    Widget kotak({required Widget child}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: child,
          ),
        );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          kotak(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 14, color: _oranye),
                  const SizedBox(width: 4),
                  Text('Target Kalori', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Text(kalori,
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Tujuan: ${c.labelTujuan}',
                  style: TextStyle(color: context.textMuted, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        kotak(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: _oranye),
                  const SizedBox(width: 4),
                  Text('Durasi Siklus', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Hari ${c.hariKe} / ${c.durasiHari}',
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progresSiklus,
                  backgroundColor: context.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(_oranye),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildDetailPenting() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detail Penting',
                  style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              _tombolSimpan(_simpanTinggi, _simpanTinggiBadan),
            ],
          ),
          const SizedBox(height: 14),
          _label('TINGGI BADAN (CM)'),
          const SizedBox(height: 6),
          _Field(
            controller: _tinggiCtrl,
            hint: 'Tinggi (cm)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _label('PERBARUI BERAT BADAN HARI INI'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _bbCtrl,
                  hint: 'Ketik BB hari ini (contoh: 71.8)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _simpanBB ? null : _simpanBeratBadan,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _simpanBB ? Colors.grey : _oranye,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _simpanBB
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownJenisKelamin() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _jenisKelamin,
          isExpanded: true,
          dropdownColor: context.card,
          hint: Text('Pilih', style: TextStyle(color: context.textMuted, fontSize: 12)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondary),
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'laki_laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'perempuan', child: Text('Perempuan')),
          ],
          onChanged: (v) => setState(() => _jenisKelamin = v),
        ),
      ),
    );
  }

  Widget _buildInformasiDiri() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Informasi Diri',
                  style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              _tombolSimpan(_simpanDiri, _simpanInformasiDiri),
            ],
          ),
          const SizedBox(height: 14),
          _label('NAMA LENGKAP'),
          const SizedBox(height: 6),
          _Field(controller: _namaCtrl, hint: 'Nama Lengkap'),
          const SizedBox(height: 12),
          _label('EMAIL'),
          const SizedBox(height: 6),
          _Field(
            controller: _emailCtrl,
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _label('USERNAME'),
          const SizedBox(height: 6),
          _Field(controller: _usernameCtrl, hint: 'Username'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('USIA'),
                    const SizedBox(height: 6),
                    _Field(
                      controller: _usiaCtrl,
                      hint: 'Usia (thn)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('JENIS KELAMIN'),
                    const SizedBox(height: 6),
                    _buildDropdownJenisKelamin(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('ALERGI & PANTANGAN MAKANAN'),
          const SizedBox(height: 6),
          _Field(controller: _alergiCtrl, hint: 'Alergi & Pantangan'),
        ],
      ),
    );
  }

  Widget _buildPengaturan(bool isDark) {
    Widget pilihTema({required bool gelap, required IconData ikon}) {
      final aktif = gelap == isDark;
      return GestureDetector(
        onTap: () => _gantiTema(gelap),
        child: Container(
          width: 34,
          height: 30,
          decoration: BoxDecoration(
            color: aktif ? _oranye : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(ikon, size: 16, color: aktif ? Colors.white : context.textSecondary),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan & Tampilan',
              style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          InkWell(
            onTap: _tampilkanUbahSandi,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: context.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text('Ubah Kata Sandi',
                          style: TextStyle(color: context.textPrimary, fontSize: 13)),
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: context.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tema Visual',
                            style: TextStyle(
                                color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(isDark ? 'Mode Gelap' : 'Mode Terang',
                            style: TextStyle(color: context.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A1310) : const Color(0xFFDDE4E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      pilihTema(gelap: false, ikon: Icons.wb_sunny_rounded),
                      const SizedBox(width: 2),
                      pilihTema(gelap: true, ikon: Icons.nightlight_round),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UbahSandiSheet extends ConsumerStatefulWidget {
  const _UbahSandiSheet();

  @override
  ConsumerState<_UbahSandiSheet> createState() => _UbahSandiSheetState();
}

class _UbahSandiSheetState extends ConsumerState<_UbahSandiSheet> {
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfCtrl = TextEditingController();

  bool _lihat = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_lamaCtrl.text.isEmpty) {
      setState(() => _error = 'Kata sandi saat ini wajib diisi.');
      return;
    }
    if (_baruCtrl.text.length < 8) {
      setState(() => _error = 'Kata sandi baru minimal 8 karakter.');
      return;
    }
    if (_baruCtrl.text != _konfCtrl.text) {
      setState(() => _error = 'Konfirmasi kata sandi tidak sama.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(_profilRepositoryProvider).ubahSandi(
            passwordLama: _lamaCtrl.text,
            passwordBaru: _baruCtrl.text,
            konfirmasi: _konfCtrl.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _pesanError(e, fallback: 'Gagal mengubah kata sandi.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        _lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 18,
        color: context.textSecondary,
      ),
      onPressed: () => setState(() => _lihat = !_lihat),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ubah Kata Sandi',
              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _Field(
            controller: _lamaCtrl,
            hint: 'Kata Sandi Saat Ini',
            obscure: !_lihat,
            suffix: toggle,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _baruCtrl,
            hint: 'Kata Sandi Baru (min. 8 karakter)',
            obscure: !_lihat,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _konfCtrl,
            hint: 'Konfirmasi Kata Sandi Baru',
            obscure: !_lihat,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: _merah, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _oranye,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan Kata Sandi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}