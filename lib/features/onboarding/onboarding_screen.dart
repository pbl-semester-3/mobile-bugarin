import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// SESUAIKAN dengan key JWT yang dipakai halaman login.
const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);
const String _kTidakAda = 'Tidak Ada (Bebas)';

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
  return 'Gagal menyimpan data. Silakan coba lagi.';
}

class _OnboardingRepository {
  Future<Map<String, dynamic>> ambilProfil({required bool prefillContoh}) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!prefillContoh) return {};
      return {
        'usia': 26,
        'jenis_kelamin': 'perempuan',
        'tinggi_badan': 168,
        'alergi': 'Laktosa, Kacang',
        'bb_sekarang': 67.0,
      };
    }
    final res = await _buatDio().get('/klien/profile');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : body;
    }
    return {};
  }

  Future<void> simpan({
    required int usia,
    required String jenisKelamin,
    required int tinggiBadan,
    required String alergi,
    required String tujuan,
    required double bbAwal,
    required double bbTujuan,
    required int durasiHari,
  }) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return;
    }
    final dio = _buatDio();
    await dio.put('/klien/profile', data: {
      'usia': usia,
      'jenis_kelamin': jenisKelamin,
      'tinggi_badan': tinggiBadan,
      'alergi': alergi,
    });
    await dio.post(
      '/klien/progress-cycles',
      data: {
        'tujuan': tujuan,
        'bb_awal_kg': bbAwal,
        'bb_tujuan_kg': bbTujuan,
        'durasi_hari': durasiHari,
      },
      // Pembuatan siklus bisa memicu generate Weekly Plan (AI), jadi diberi waktu lebih.
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final String mode;
  const OnboardingScreen({this.mode = 'first-time', super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _storage = const FlutterSecureStorage();
  final _repo = _OnboardingRepository();

  bool isMale = true;
  int _age = 26;
  int _height = 175;
  final List<String> _allergyOptions = [
    'Kacang',
    'Laktosa',
    'Gluten',
    'Seafood',
    _kTidakAda,
  ];
  final List<String> _selectedAllergies = [_kTidakAda];
  int _targetGoalIndex = 0;
  double _currentWeight = 72.5;
  double _targetWeight = 67.0;

  int _selectedDuration = 60;

  bool _isSaving = false;

  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _otherAllergyController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '$_age');
    _heightController = TextEditingController(text: '$_height');
    _currentWeightController = TextEditingController(text: '$_currentWeight');
    _targetWeightController = TextEditingController(text: '$_targetWeight');
    _otherAllergyController = TextEditingController();
    _muatDataAwal();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }


  int _batas(int v, int min, int max) => v < min ? min : (v > max ? max : v);

  Future<void> _muatDataAwal() async {
    try {
      final p = await _repo.ambilProfil(prefillContoh: widget.mode == 'new-cycle');
      if (!mounted || p.isEmpty) return;

      setState(() {
        final usia = int.tryParse('${p['usia'] ?? ''}');
        if (usia != null) {
          _age = _batas(usia, 14, 85);
          _ageController.text = '$_age';
        }

        final tinggi = double.tryParse('${p['tinggi_badan'] ?? ''}');
        if (tinggi != null) {
          _height = _batas(tinggi.round(), 120, 230);
          _heightController.text = '$_height';
        }

        final jk = '${p['jenis_kelamin'] ?? ''}'.toLowerCase();
        if (jk == 'perempuan' || jk == 'p') isMale = false;
        if (jk == 'laki_laki' || jk == 'l') isMale = true;

        final bb = double.tryParse('${p['bb_sekarang'] ?? ''}');
        if (bb != null && bb > 30 && bb < 250) {
          _currentWeight = bb;
          _currentWeightController.text = bb.toStringAsFixed(1);
        }

        final alergi = p['alergi'];
        if (alergi != null) {
          _terapkanAlergi(alergi is List ? alergi.join(', ') : alergi.toString());
        }
      });
    } catch (_) {
     
    }
  }

  void _terapkanAlergi(String raw) {
    final bagian = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.toLowerCase().startsWith('tidak ada'))
        .toList();
    final dikenal = <String>[];
    final lain = <String>[];

    for (final b in bagian) {
      final cocok = _allergyOptions.where(
        (o) => o != _kTidakAda && o.toLowerCase() == b.toLowerCase(),
      );
      if (cocok.isNotEmpty) {
        dikenal.add(cocok.first);
      } else {
        lain.add(b);
      }
    }

    _selectedAllergies.clear();
    if (dikenal.isEmpty && lain.isEmpty) {
      _selectedAllergies.add(_kTidakAda);
    } else {
      _selectedAllergies.addAll(dikenal);
    }
    _otherAllergyController.text = lain.join(', ');
  }

  String _alergiUntukDikirim() {
    final daftar = _selectedAllergies.where((a) => a != _kTidakAda).toList();
    final lain = _otherAllergyController.text.trim();
    if (lain.isNotEmpty) daftar.add(lain);
    return daftar.isEmpty ? 'Tidak ada' : daftar.join(', ');
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (allergy == _kTidakAda) {
        _selectedAllergies.clear();
        _selectedAllergies.add(_kTidakAda);
      } else {
        _selectedAllergies.remove(_kTidakAda);
        if (_selectedAllergies.contains(allergy)) {
          _selectedAllergies.remove(allergy);
          if (_selectedAllergies.isEmpty) _selectedAllergies.add(_kTidakAda);
        } else {
          _selectedAllergies.add(allergy);
        }
      }
    });
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


  Future<void> submitData() async {
    if (_isSaving) return;

    final usia = int.tryParse(_ageController.text.trim());
    final tinggi = int.tryParse(_heightController.text.trim());
    final bbAwal = double.tryParse(_currentWeightController.text.trim().replaceAll(',', '.'));
    final bbTujuan = double.tryParse(_targetWeightController.text.trim().replaceAll(',', '.'));
    final turun = _targetGoalIndex == 0;

    String? pesan;
    if (usia == null || usia < 14 || usia > 85) {
      pesan = 'Usia harus antara 14 dan 85 tahun.';
    } else if (tinggi == null || tinggi < 120 || tinggi > 230) {
      pesan = 'Tinggi badan harus antara 120 dan 230 cm.';
    } else if (bbAwal == null || bbAwal < 30 || bbAwal > 250) {
      pesan = 'Berat badan awal harus antara 30 dan 250 kg.';
    } else if (bbTujuan == null || bbTujuan < 30 || bbTujuan > 250) {
      pesan = 'Berat badan tujuan harus antara 30 dan 250 kg.';
    } else if (turun && bbTujuan >= bbAwal) {
      pesan = 'Untuk target Turun BB, berat badan tujuan harus lebih kecil dari berat badan awal.';
    } else if (!turun && bbTujuan <= bbAwal) {
      pesan = 'Untuk target Naik BB, berat badan tujuan harus lebih besar dari berat badan awal.';
    }
    if (pesan != null) {
      _toast(pesan, error: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.simpan(
        usia: usia!,
        jenisKelamin: isMale ? 'laki_laki' : 'perempuan',
        tinggiBadan: tinggi!,
        alergi: _alergiUntukDikirim(),
        tujuan: turun ? 'turun_bb' : 'naik_bb',
        bbAwal: bbAwal!,
        bbTujuan: bbTujuan!,
        durasiHari: _selectedDuration,
      );

      await _storage.write(key: 'has_completed_profile', value: 'true');

      ref.read(authStateProvider.notifier).markProfileComplete();

      if (!mounted) return;
      if (widget.mode == 'new-cycle') {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      _toast(_pesanError(e), error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const accent = _oranye;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : null,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                    ),
                    child: Text(
                      widget.mode == 'new-cycle' ? 'SIKLUS BARU' : 'LANGKAH 1 DARI 1',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target & Profil Fisik',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Data esensial untuk perhitungan target kalori cerdas AI & generate Weekly Plan personal yang adaptif.',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profil Dasar Klien',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'KLIEN PROFILES',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jenis Kelamin Biologis Wajib',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderBtn('Pria', Icons.male_rounded, isMale,
                                    () => setState(() => isMale = true)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildGenderBtn('Wanita', Icons.female_rounded, !isMale,
                                    () => setState(() => isMale = false)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCounterField(
                                  'USIA',
                                  'tahun',
                                  _ageController,
                                  () {
                                    if (_age > 14) {
                                      setState(() {
                                        _age--;
                                        _ageController.text = _age.toString();
                                      });
                                    }
                                  },
                                  () {
                                    if (_age < 85) {
                                      setState(() {
                                        _age++;
                                        _ageController.text = _age.toString();
                                      });
                                    }
                                  },
                                  (v) {
                                    final val = int.tryParse(v);
                                    if (val != null) setState(() => _age = val);
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: context.border,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              Expanded(
                                child: _buildCounterField(
                                  'TINGGI',
                                  'cm',
                                  _heightController,
                                  () {
                                    if (_height > 120) {
                                      setState(() {
                                        _height--;
                                        _heightController.text = _height.toString();
                                      });
                                    }
                                  },
                                  () {
                                    if (_height < 230) {
                                      setState(() {
                                        _height++;
                                        _heightController.text = _height.toString();
                                      });
                                    }
                                  },
                                  (v) {
                                    final val = int.tryParse(v);
                                    if (val != null) setState(() => _height = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: ALERGI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alergi & Preferensi Diet',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pilih multi',
                          style: TextStyle(color: context.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _allergyOptions.map((opt) {
                              final active = _selectedAllergies.contains(opt);
                              return GestureDetector(
                                onTap: () => _toggleAllergy(opt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? (opt.contains('Tidak')
                                            ? const Color(0xFFE0F2F1)
                                            : const Color(0xFFFFECE5))
                                        : context.surfaceInner,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active
                                          ? (opt.contains('Tidak') ? Colors.teal : accent)
                                          : context.border,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: active
                                          ? (opt.contains('Tidak') ? Colors.teal[700] : accent)
                                          : context.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: context.border)),
                            ),
                            child: TextField(
                              controller: _otherAllergyController,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ada batasan lain? (cth: Vegan, Halal)',
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                                border: InputBorder.none,
                                suffixIcon: Icon(Icons.edit_note_rounded,
                                    color: context.textMuted, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Siklus & Target Progres',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PROGRESS CYCLES',
                          style: TextStyle(color: context.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arah Sasaran Siklus Ini',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildGoalBtn('Turun BB', 'DEFISIT KALORI', 0)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildGoalBtn('Naik BB', 'MASSA OTOT', 1)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWeightRow(
                            'Berat Badan Awal',
                            'Masuk ke log berat perdana',
                            _currentWeightController,
                            () {
                              setState(() {
                                if (_currentWeight > 30) {
                                  _currentWeight -= 0.5;
                                  _currentWeightController.text = _currentWeight.toStringAsFixed(1);
                                }
                              });
                            },
                            () {
                              setState(() {
                                if (_currentWeight < 250) {
                                  _currentWeight += 0.5;
                                  _currentWeightController.text = _currentWeight.toStringAsFixed(1);
                                }
                              });
                            },
                            (v) {
                              final val = double.tryParse(v);
                              if (val != null) setState(() => _currentWeight = val);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(color: context.border),
                          ),
                          _buildWeightRow(
                            'Berat Badan Tujuan',
                            'Target akhir siklus',
                            _targetWeightController,
                            () {
                              setState(() {
                                if (_targetWeight > 30) {
                                  _targetWeight -= 0.5;
                                  _targetWeightController.text = _targetWeight.toStringAsFixed(1);
                                }
                              });
                            },
                            () {
                              setState(() {
                                if (_targetWeight < 250) {
                                  _targetWeight += 0.5;
                                  _targetWeightController.text = _targetWeight.toStringAsFixed(1);
                                }
                              });
                            },
                            (v) {
                              final val = double.tryParse(v);
                              if (val != null) setState(() => _targetWeight = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: DURASI SIKLUS KOMITMEN
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Siklus Komitmen',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildDurationCard(30, 'Hari (Sprint)', false, accent),
                              const SizedBox(width: 10),
                              _buildDurationCard(60, 'Hari (Ideal)', true, accent),
                              const SizedBox(width: 10),
                              _buildDurationCard(90, 'Hari (Transf.)', false, accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // TOMBOL UTAMA
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan & Mulai Siklus',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDurationCard(int days, String label, bool isBest, Color accent) {
    final active = _selectedDuration == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = days),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFECE5) : context.surfaceInner,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? accent : context.border,
                  width: active ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: TextStyle(
                      color: active ? accent : context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? accent : context.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isBest)
              Positioned(
                top: -8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBtn(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _oranye : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? _oranye : context.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : context.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterField(
    String label,
    String unit,
    TextEditingController ctrl,
    VoidCallback onDec,
    VoidCallback onInc,
    Function(String) onChanged,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            IntrinsicWidth(
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(color: context.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBtn(Icons.remove, onDec),
            const SizedBox(width: 16),
            _buildBtn(Icons.add, onInc),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalBtn(String title, String sub, int index) {
    final active = _targetGoalIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _targetGoalIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _oranye : context.surfaceInner,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? _oranye : context.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : context.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: active ? Colors.white70 : context.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightRow(
    String title,
    String sub,
    TextEditingController ctrl,
    VoidCallback onDec,
    VoidCallback onInc,
    Function(String) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: context.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Row(
          children: [
            _buildBtn(Icons.remove, onDec),
            const SizedBox(width: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                IntrinsicWidth(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 2),
                Text('kg', style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 12),
            _buildBtn(Icons.add, onInc),
          ],
        ),
      ],
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.surfaceInner,
          shape: BoxShape.circle,
          border: Border.all(color: context.border),
        ),
        child: Icon(icon, size: 14, color: context.textPrimary),
      ),
    );
  }
}