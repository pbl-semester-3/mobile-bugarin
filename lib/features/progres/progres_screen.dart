import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);

// Jika nama key dari backend berbeda, cukup ubah di fromJson / parser.

double? _toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

class MasterOlahraga {
  final dynamic rawId;
  final String nama;
  final bool butuhJarak;
  final double met;

  const MasterOlahraga({
    required this.rawId,
    required this.nama,
    required this.butuhJarak,
    required this.met,
  });

  String get id => rawId.toString();

  factory MasterOlahraga.fromJson(Map<String, dynamic> j) {
    final jarak = j['butuh_jarak'];
    return MasterOlahraga(
      rawId: j['id'],
      nama: (j['nama'] ?? '').toString(),
      butuhJarak: jarak == true || jarak == 1 || jarak == 'true',
      met: _toDouble(j['met']) ?? 0,
    );
  }
}

class MealItem {
  final String id; 
  final dynamic makananId;
  final String nama;
  double? kaloriPer100g;
  int gram;
  bool isSelected;
  final bool isCustom;

  MealItem({
    required this.id,
    this.makananId,
    required this.nama,
    required this.kaloriPer100g,
    required this.gram,
    this.isSelected = true,
    this.isCustom = false,
  });

  int get totalKalori =>
      kaloriPer100g == null ? 0 : ((gram / 100) * kaloriPer100g!).round();
}

class _LogMakanan {
  final dynamic makananId;
  final String nama;
  final int gram;
  final double? kaloriPer100g;
  final String? sumber;

  const _LogMakanan({
    required this.makananId,
    required this.nama,
    required this.gram,
    required this.kaloriPer100g,
    required this.sumber,
  });

  factory _LogMakanan.fromJson(Map<String, dynamic> j) {
    final gram = _toInt(j['porsi_gram']) ?? 0;
    var per100 = _toDouble(j['kalori_per_100g']);
    final total = _toDouble(j['kalori']);
    if (per100 == null && total != null && gram > 0) per100 = total / gram * 100;
    return _LogMakanan(
      makananId: j['makanan_id'],
      nama: (j['nama'] ?? j['nama_makanan'] ?? '').toString(),
      gram: gram,
      kaloriPer100g: per100,
      sumber: j['sumber']?.toString(),
    );
  }
}

class ActivityLogItem {
  final String namaOlahraga;
  final int durasiMenit;
  final int? jarakMeter;
  final int kaloriTerbakar;

  ActivityLogItem({
    required this.namaOlahraga,
    required this.durasiMenit,
    this.jarakMeter,
    required this.kaloriTerbakar,
  });
}

class _PlanItem {
  final String judul;
  final String? subjudul;
  final bool hariIni;
  const _PlanItem({required this.judul, this.subjudul, this.hariIni = false});
}

class _WeeklyPlan {
  final String? status;
  final List<_PlanItem> workout;
  final List<_PlanItem> meal;

  const _WeeklyPlan({required this.status, required this.workout, required this.meal});

  /// Rencana baru tampil bila sudah disetujui PT (status != pending_review).
  bool get disetujui => status != null && status != 'pending_review';

  factory _WeeklyPlan.fromJson(Map<String, dynamic> j) {
    return _WeeklyPlan(
      status: j['status']?.toString(),
      workout: _parsePlan(j['workout_plan'], workout: true),
      meal: _parsePlan(j['meal_plan'], workout: false),
    );
  }
}

String _namaHariIni() {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return hari[DateTime.now().weekday - 1];
}

List<_PlanItem> _parsePlan(dynamic raw, {required bool workout}) {
  final hariIni = _namaHariIni().toLowerCase();

  String gabung(List<String?> bagian) =>
      bagian.where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).join(' • ');

  if (raw is String && raw.trim().isNotEmpty) {
    return [_PlanItem(judul: raw.trim())];
  }

  if (raw is List) {
    final hasil = <_PlanItem>[];
    for (final e in raw) {
      if (e is String && e.trim().isNotEmpty) {
        hasil.add(_PlanItem(judul: e.trim()));
      } else if (e is Map) {
        final hari = e['hari']?.toString();
        final judul = workout
            ? (e['jenis'] ?? e['nama'] ?? e['judul'] ?? '-').toString()
            : (e['menu'] ?? e['nama'] ?? e['deskripsi'] ?? '-').toString();
        final sub = workout
            ? gabung([hari, e['jam']?.toString()])
            : gabung([
                hari,
                (e['waktu'] ?? e['waktu_makan'])?.toString(),
                e['kalori'] == null ? null : '${e['kalori']} kkal',
              ]);
        hasil.add(_PlanItem(
          judul: judul,
          subjudul: sub.isEmpty ? null : sub,
          hariIni: hari != null && hari.toLowerCase() == hariIni,
        ));
      }
    }
    return hasil;
  }

  if (raw is Map) {
    return [
      for (final entry in raw.entries)
        _PlanItem(
          judul: entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString(),
          subjudul: entry.key.toString(),
          hariIni: entry.key.toString().toLowerCase() == hariIni,
        ),
    ];
  }

  return const [];
}

Dio _buatDio() {
  const storage = FlutterSecureStorage();
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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

dynamic _isiBody(dynamic body, [String? key]) {
  if (body is Map) return body['data'] ?? (key == null ? null : body[key]) ?? body;
  return body;
}

List<Map<String, dynamic>> _listMap(dynamic body, [String? key]) {
  final isi = _isiBody(body, key);
  if (isi is List) return isi.whereType<Map<String, dynamic>>().toList();
  return const [];
}

class _ProgresRepository {
  // ----- penyimpanan dummy (bertahan selama aplikasi berjalan) -----
  static List<_LogMakanan>? _mockLogMakanan;
  static final List<ActivityLogItem> _mockAktivitas = [
    ActivityLogItem(
      namaOlahraga: 'Latihan Beban (Hypertrophy)',
      durasiMenit: 45,
      kaloriTerbakar: 260,
    ),
  ];

  Future<void> _tunda([int ms = 500]) => Future.delayed(Duration(milliseconds: ms));

  /// GET /master/olahraga
  Future<List<MasterOlahraga>> ambilMasterOlahraga() async {
    if (_kPakaiMock) {
      await _tunda();
      return const [
        MasterOlahraga(rawId: 1, nama: 'Lari Santai (Jogging)', butuhJarak: true, met: 7.0),
        MasterOlahraga(rawId: 2, nama: 'Bersepeda Luar Ruangan', butuhJarak: true, met: 6.8),
        MasterOlahraga(rawId: 3, nama: 'Renang Gaya Bebas', butuhJarak: true, met: 8.0),
        MasterOlahraga(rawId: 4, nama: 'Latihan Beban (Hypertrophy)', butuhJarak: false, met: 5.0),
        MasterOlahraga(rawId: 5, nama: 'Kalistenik & Core', butuhJarak: false, met: 4.5),
        MasterOlahraga(rawId: 6, nama: 'HIIT Circuit', butuhJarak: false, met: 8.5),
      ];
    }
    final res = await _buatDio().get('/master/olahraga');
    return _listMap(res.data, 'olahraga').map(MasterOlahraga.fromJson).toList();
  }

  /// GET /master/makanan  (hanya yang ditandai preset)
  Future<List<MealItem>> ambilPresetMakanan() async {
    List<Map<String, dynamic>> data;

    if (_kPakaiMock) {
      await _tunda();
      data = [
        {'id': 1, 'nama': 'Nasi Merah', 'kalori_per_100g': 150, 'preset': true, 'porsi_default_gram': 150},
        {'id': 2, 'nama': 'Dada Ayam', 'kalori_per_100g': 165, 'preset': true, 'porsi_default_gram': 150},
        {'id': 3, 'nama': 'Ikan Tuna Panggang', 'kalori_per_100g': 130, 'preset': true, 'porsi_default_gram': 100},
        {'id': 4, 'nama': 'Sayur Bayam & Wortel', 'kalori_per_100g': 35, 'preset': true, 'porsi_default_gram': 100},
      ];
    } else {
      final res = await _buatDio().get('/master/makanan');
      data = _listMap(res.data, 'makanan');
    }

    bool preset(Map<String, dynamic> m) {
      final p = m['preset'] ?? m['is_preset'];
      return p == true || p == 1 || p == 'true';
    }

    final dipilih = data.any(preset) ? data.where(preset).toList() : data;

    return [
      for (final m in dipilih)
        MealItem(
          id: 'm_${m['id']}',
          makananId: m['id'],
          nama: (m['nama'] ?? '').toString(),
          kaloriPer100g: _toDouble(m['kalori_per_100g'] ?? m['kalori']),
          gram: _toInt(m['porsi_default_gram']) ?? 100,
        ),
    ];
  }

  Future<_WeeklyPlan?> ambilPlan() async {
    if (_kPakaiMock) {
      await _tunda();
      return _WeeklyPlan.fromJson({
        'status': 'approved',
        'workout_plan': [
          {'hari': 'Senin', 'jam': '16:30 - 17:30', 'jenis': 'Upper Body Hypertrophy & Core Power'},
          {'hari': 'Rabu', 'jam': '16:30 - 17:30', 'jenis': 'Lower Body & Core'},
          {'hari': 'Jumat', 'jam': '16:30 - 17:30', 'jenis': 'Full Body Circuit'},
        ],
        'meal_plan': [
          {'waktu': 'Sarapan', 'menu': 'Oatmeal, telur rebus, dan pisang', 'kalori': 450},
          {'waktu': 'Makan Siang', 'menu': 'Nasi merah, dada ayam, sayur bayam', 'kalori': 650},
          {'waktu': 'Makan Malam', 'menu': 'Ikan tuna panggang dan salad', 'kalori': 500},
        ],
      });
    }
    try {
      final res = await _buatDio().get('/klien/weekly-plan/current');
      final isi = _isiBody(res.data);
      if (isi is! Map<String, dynamic> || isi.isEmpty) return null;
      return _WeeklyPlan.fromJson(isi);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<_LogMakanan>> ambilLogMakananHariIni() async {
    if (_kPakaiMock) return _mockLogMakanan ?? const [];
    try {
      final res = await _buatDio().get('/klien/meal-logs', queryParameters: {'tanggal': 'today'});
      return _listMap(res.data, 'items').map(_LogMakanan.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ActivityLogItem>> ambilLogOlahragaHariIni() async {
    if (_kPakaiMock) return List.of(_mockAktivitas);
    try {
      final res = await _buatDio().get('/klien/activity-logs', queryParameters: {'tanggal': 'today'});
      return [
        for (final j in _listMap(res.data, 'logs'))
          ActivityLogItem(
            namaOlahraga: (j['nama_olahraga'] ?? j['olahraga'] ?? '-').toString(),
            durasiMenit: _toInt(j['durasi_menit']) ?? 0,
            jarakMeter: _toInt(j['jarak_meter']),
            kaloriTerbakar: _toDouble(j['kalori_terbakar'])?.round() ?? 0,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

   Future<Map<String, double>> simpanMeal(List<MealItem> items) async {
    if (_kPakaiMock) {
      await _tunda(800);
      final hasil = <String, double>{};
      for (final m in items) {
        hasil[m.nama.toLowerCase()] = m.kaloriPer100g ?? 135;
      }
      _mockLogMakanan = [
        for (final m in items)
          _LogMakanan(
            makananId: m.makananId,
            nama: m.nama,
            gram: m.gram,
            kaloriPer100g: m.kaloriPer100g ?? 135,
            sumber: m.isCustom ? 'ai_generated' : null,
          ),
      ];
      return hasil;
    }

    final res = await _buatDio().post('/klien/meal-logs', data: {
      'items': [
        for (final m in items)
          if (m.makananId != null)
            {'makanan_id': m.makananId, 'porsi_gram': m.gram}
          else
            {'nama_makanan': m.nama, 'porsi_gram': m.gram},
      ],
    });

    final hasil = <String, double>{};
    for (final j in _listMap(res.data, 'items')) {
      final log = _LogMakanan.fromJson(j);
      if (log.nama.isNotEmpty && log.kaloriPer100g != null) {
        hasil[log.nama.toLowerCase()] = log.kaloriPer100g!;
      }
    }
    return hasil;
  }

  Future<ActivityLogItem> catatAktivitas({
    required MasterOlahraga olahraga,
    required int durasi,
    int? jarak,
  }) async {
    if (_kPakaiMock) {
      await _tunda(700);
      const beratBadanKg = 70.0;
      final kalori = ((olahraga.met * 3.5 * beratBadanKg / 200) * durasi).round();
      final item = ActivityLogItem(
        namaOlahraga: olahraga.nama,
        durasiMenit: durasi,
        jarakMeter: jarak,
        kaloriTerbakar: kalori,
      );
      _mockAktivitas.insert(0, item);
      return item;
    }

    final res = await _buatDio().post('/klien/activity-logs', data: {
      'olahraga_id': olahraga.rawId,
      'durasi_menit': durasi,
      if (jarak != null) 'jarak_meter': jarak,
    });
    final isi = _isiBody(res.data);
    final map = isi is Map<String, dynamic> ? isi : <String, dynamic>{};
    return ActivityLogItem(
      namaOlahraga: olahraga.nama,
      durasiMenit: durasi,
      jarakMeter: jarak,
      kaloriTerbakar: _toDouble(map['kalori_terbakar'])?.round() ?? 0,
    );
  }
}


class ProgresScreen extends StatefulWidget {
  const ProgresScreen({super.key});

  @override
  State<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends State<ProgresScreen> {
  final _repo = _ProgresRepository();

  bool _isMealTab = true;

  final TextEditingController _customMenuController = TextEditingController();
  final TextEditingController _customGramController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _jarakController = TextEditingController();

  bool _memuat = true;
  String? _errorMuat;

  List<MealItem> _meals = [];
  List<MasterOlahraga> _masterOlahragaList = [];
  String? _selectedOlahragaId;
  List<ActivityLogItem> _submittedActivities = [];

  _WeeklyPlan? _plan;
  String? _planError;

  bool _simpanMealLoading = false;
  bool _simpanLatihanLoading = false;

  MasterOlahraga? get _selectedOlahraga {
    for (final o in _masterOlahragaList) {
      if (o.id == _selectedOlahragaId) return o;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _customMenuController.dispose();
    _customGramController.dispose();
    _durasiController.dispose();
    _jarakController.dispose();
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
        _repo.ambilMasterOlahraga(),
        _repo.ambilPresetMakanan(),
        _repo.ambilLogMakananHariIni(),
        _repo.ambilLogOlahragaHariIni(),
      ]);

      final olahraga = hasil[0] as List<MasterOlahraga>;
      final presets = hasil[1] as List<MealItem>;
      final logMakanan = hasil[2] as List<_LogMakanan>;
      final logOlahraga = hasil[3] as List<ActivityLogItem>;

      _WeeklyPlan? plan;
      String? planError;
      try {
        plan = await _repo.ambilPlan();
      } catch (e) {
        planError = _pesanError(e, fallback: 'Rencana mingguan tidak dapat dimuat.');
      }

      if (!mounted) return;
      setState(() {
        _masterOlahragaList = olahraga;
        final adaTerpilih = olahraga.any((o) => o.id == _selectedOlahragaId);
        if (!adaTerpilih) {
          _selectedOlahragaId = olahraga.isEmpty ? null : olahraga.first.id;
        }
        _meals = _susunMeal(presets, logMakanan);
        _submittedActivities = logOlahraga;
        _plan = plan;
        _planError = planError;
        _errorMuat = null;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMuat = _pesanError(e, fallback: 'Gagal memuat data progres.');
        _memuat = false;
      });
    }
  }

  List<MealItem> _susunMeal(List<MealItem> presets, List<_LogMakanan> log) {
    if (log.isEmpty) return presets;

    for (final p in presets) {
      p.isSelected = false;
    }
    var seq = 0;
    for (final l in log) {
      MealItem? cocok;
      if (l.makananId != null) {
        for (final p in presets) {
          if (p.makananId.toString() == l.makananId.toString()) {
            cocok = p;
            break;
          }
        }
      }
      if (cocok != null) {
        cocok.gram = l.gram;
        cocok.isSelected = true;
      } else {
        presets.add(MealItem(
          id: 'log_${seq++}_${l.nama}',
          makananId: l.makananId,
          nama: l.nama,
          kaloriPer100g: l.kaloriPer100g,
          gram: l.gram,
          isSelected: true,
          isCustom: true,
        ));
      }
    }
    return presets;
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

  int get _totalKaloriMasuk {
    var total = 0;
    for (final m in _meals) {
      if (m.isSelected) total += m.totalKalori;
    }
    return total;
  }

  int get _jumlahBelumDiestimasi =>
      _meals.where((m) => m.isSelected && m.kaloriPer100g == null).length;

  int get _totalKaloriTerbakar {
    var total = 0;
    for (final act in _submittedActivities) {
      total += act.kaloriTerbakar;
    }
    return total;
  }

  void _addCustomMeal() {
    final name = _customMenuController.text.trim();
    final gram = int.tryParse(_customGramController.text.trim());

    if (name.isEmpty || gram == null || gram <= 0) {
      _toast('Nama makanan dan porsi gram wajib diisi dengan benar.', error: true);
      return;
    }

    setState(() {
      _meals.add(
        MealItem(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          nama: name,
          kaloriPer100g: null,
          gram: gram,
          isSelected: true,
          isCustom: true,
        ),
      );
      _customMenuController.clear();
      _customGramController.clear();
    });
  }

  void _editPortionDialog(MealItem meal) {
    final controller = TextEditingController(text: meal.gram.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.border),
        ),
        title: Text(
          'Ubah Porsi ${meal.nama}',
          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Porsi (gram)',
            labelStyle: TextStyle(color: context.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _oranye)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                setState(() => meal.gram = val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _oranye,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _resetMeals() {
    setState(() {
      for (final meal in _meals) {
        meal.isSelected = false;
      }
      _meals.removeWhere((item) => item.isCustom);
      _customMenuController.clear();
      _customGramController.clear();
    });
  }

  Future<void> _simpanMeal() async {
    final dipilih = _meals.where((m) => m.isSelected).toList();
    if (dipilih.isEmpty) {
      _toast('Pilih minimal satu makanan sebelum menyimpan.', error: true);
      return;
    }

    setState(() => _simpanMealLoading = true);
    try {
      final kaloriPer100g = await _repo.simpanMeal(dipilih);
      if (!mounted) return;

      setState(() {
        for (final m in dipilih) {
          final est = kaloriPer100g[m.nama.toLowerCase()];
          if (m.kaloriPer100g == null && est != null) m.kaloriPer100g = est;
        }
      });
      _toast('Tersimpan: $_totalKaloriMasuk kkal tercatat hari ini.');
    } catch (e) {
      _toast(_pesanError(e, fallback: 'Gagal menyimpan makanan.'), error: true);
    } finally {
      if (mounted) setState(() => _simpanMealLoading = false);
    }
  }


  Future<void> _submitActivity() async {
    final olahraga = _selectedOlahraga;
    if (olahraga == null) {
      _toast('Pilih jenis olahraga terlebih dahulu.', error: true);
      return;
    }

    final durasi = int.tryParse(_durasiController.text.trim());
    if (durasi == null || durasi <= 0) {
      _toast('Durasi olahraga (menit) wajib diisi.', error: true);
      return;
    }

    int? jarak;
    if (olahraga.butuhJarak) {
      jarak = int.tryParse(_jarakController.text.trim());
      if (jarak == null || jarak <= 0) {
        _toast('Olahraga ini mewajibkan input jarak tempuh (meter).', error: true);
        return;
      }
    }

    setState(() => _simpanLatihanLoading = true);
    try {
      final hasil = await _repo.catatAktivitas(olahraga: olahraga, durasi: durasi, jarak: jarak);
      if (!mounted) return;
      setState(() {
        _submittedActivities.insert(0, hasil);
        _durasiController.clear();
        _jarakController.clear();
      });
      _toast('Aktivitas tersimpan. Terbakar: ${hasil.kaloriTerbakar} kkal.');
    } catch (e) {
      _toast(_pesanError(e, fallback: 'Gagal mencatat aktivitas.'), error: true);
    } finally {
      if (mounted) setState(() => _simpanLatihanLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
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
                const BugarinHeader(subtitle: 'Progres'),
                const SizedBox(height: 22),
                Text(
                  'Progres Harian',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau asupan nutrisi dan aktivitas latihan terpadu.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _buildTabSwitch(),
                const SizedBox(height: 20),
                if (_memuat)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: _oranye, strokeWidth: 2.2),
                    ),
                  )
                else if (_errorMuat != null)
                  _buildError()
                else if (_isMealTab)
                  _buildMealSection()
                else
                  _buildOlahragaSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildTabSwitch() {
    Widget tab(String label, bool aktif, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: aktif ? _oranye : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: aktif ? Colors.white : context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          tab('Meal (Nutrisi)', _isMealTab, () => setState(() => _isMealTab = true)),
          tab('Olahraga', !_isMealTab, () => setState(() => _isMealTab = false)),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String chip,
    required String judul,
    required List<_PlanItem> Function(_WeeklyPlan) ambil,
    required String kosong,
  }) {
    final plan = _plan;
    Widget isi;

    if (_planError != null) {
      isi = _teksInfo(_planError!);
    } else if (plan == null || !plan.disetujui) {
      isi = _teksInfo('Menunggu PT menyetujui rencana mingguan Anda.');
    } else {
      final items = ambil(plan);
      isi = items.isEmpty
          ? _teksInfo(kosong)
          : Column(children: [for (final it in items) _buildPlanRow(it)]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border),
            ),
            child: Text(
              chip,
              style: const TextStyle(
                color: _oranye,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            judul,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          isi,
        ],
      ),
    );
  }

  Widget _teksInfo(String teks) {
    return Text(
      teks,
      style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
    );
  }

  Widget _buildPlanRow(_PlanItem it) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: it.hariIni ? _oranye : context.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.judul,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                if (it.subjudul != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    it.subjudul!,
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (it.hariIni) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _oranye,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'HARI INI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlanCard(
          chip: 'WEEKLY PLAN • MEAL',
          judul: 'Rencana Menu Minggu Ini',
          ambil: (p) => p.meal,
          kosong: 'Belum ada rencana menu pada minggu ini.',
        ),
        const SizedBox(height: 22),
        Text(
          'Preset Makanan Hari Ini',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Belum ada daftar makanan.',
              style: TextStyle(color: context.textMuted, fontSize: 12),
            ),
          ),
        for (final meal in _meals) _buildMealRow(meal),
        const SizedBox(height: 20),
        Text(
          'Tambah Menu Khusus (Custom Entry)',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Jika makanan belum terdaftar, sistem akan mengestimasi kalori otomatis saat disimpan.',
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _inputKotak(
                controller: _customMenuController,
                hint: 'Ketik Menu Anda',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _inputKotak(
                controller: _customGramController,
                hint: 'Porsi (g)',
                angka: true,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addCustomMeal,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _oranye,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL KALORI MASUK',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalKaloriMasuk kkal',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_jumlahBelumDiestimasi > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+ $_jumlahBelumDiestimasi menu custom akan dihitung AI saat disimpan',
                  style: const TextStyle(color: _oranye, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _simpanMealLoading ? null : _resetMeals,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _simpanMealLoading ? null : _simpanMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _oranye,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _oranye.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _simpanMealLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputKotak({
    required TextEditingController controller,
    required String hint,
    bool angka = false,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: angka ? TextInputType.number : TextInputType.text,
        inputFormatters: angka ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMealRow(MealItem meal) {
    final subteks = meal.kaloriPer100g == null
        ? 'Kalori diestimasi AI saat disimpan'
        : '${meal.totalKalori} kkal (${meal.kaloriPer100g!.round()} kkal/100g)';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: meal.isSelected ? _oranye.withValues(alpha: 0.4) : context.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meal.nama,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meal.isCustom) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.surfaceInner,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: _oranye,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subteks,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editPortionDialog(meal),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.surfaceInner,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.border),
              ),
              child: Text(
                '${meal.gram} g',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => meal.isSelected = !meal.isSelected),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: meal.isSelected ? _oranye : context.surfaceInner,
                shape: BoxShape.circle,
                border: Border.all(
                  color: meal.isSelected ? Colors.transparent : context.border,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: meal.isSelected ? Colors.white : context.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlahragaSection() {
    final terpilih = _selectedOlahraga;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlanCard(
          chip: 'WEEKLY PLAN • WORKOUT',
          judul: 'Jadwal Latihan Minggu Ini',
          ambil: (p) => p.workout,
          kosong: 'Belum ada jadwal latihan pada minggu ini.',
        ),
        const SizedBox(height: 22),
        Text(
          'Catat Aktivitas Latihan',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: terpilih?.id,
              isExpanded: true,
              dropdownColor: context.card,
              hint: Text('Pilih jenis olahraga',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _oranye),
              items: [
                for (final item in _masterOlahragaList)
                  DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.nama,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedOlahragaId = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border),
          ),
          child: TextField(
            controller: _durasiController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: context.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Durasi Latihan (menit)',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        // Jarak hanya tampil untuk olahraga dengan butuh_jarak = true (PRD 3.5).
        if (terpilih != null && terpilih.butuhJarak) ...[
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _oranye.withValues(alpha: 0.6)),
            ),
            child: TextField(
              controller: _jarakController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Jarak Tempuh (meter) *Wajib',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _simpanLatihanLoading ? null : _submitActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: _oranye,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _oranye.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _simpanLatihanLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Catat Latihan Ini', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Hari Ini',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: $_totalKaloriTerbakar kkal',
              style: const TextStyle(
                color: _oranye,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_submittedActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada aktivitas yang dicatat hari ini.',
              style: TextStyle(color: context.textMuted, fontSize: 12),
            ),
          ),
        for (final act in _submittedActivities)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.namaOlahraga,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        act.jarakMeter != null
                            ? '${act.durasiMenit} menit • ${act.jarakMeter} meter'
                            : '${act.durasiMenit} menit',
                        style: TextStyle(color: context.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.surfaceInner,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${act.kaloriTerbakar} kkal',
                    style: const TextStyle(
                      color: _oranye,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}