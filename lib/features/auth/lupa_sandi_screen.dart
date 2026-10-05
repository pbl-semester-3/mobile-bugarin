import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme_provider.dart';
/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
/// Di mode dummy, kode verifikasi yang benar adalah 123456.
const bool _kPakaiMock = true;
const String _kKodeDummy = '123456';

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' 
    : 'http://10.0.2.2:3000/api';

const Color _oranye = Color(0xFFFF5520);
const Color _merah = Color(0xFFE53935);

// (Endpoint ini belum ada di PRD, perlu ditambahkan oleh tim backend.)

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

class _PemulihanRepository {
  Dio _dio() => Dio(
        BaseOptions(
          baseUrl: _kBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      );

  Future<void> kirimKode(String email) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return;
    }
    await _dio().post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetSandi({
    required String email,
    required String kode,
    required String passwordBaru,
    required String konfirmasi,
  }) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (kode != _kKodeDummy) {
        throw Exception('Kode verifikasi salah atau sudah kedaluwarsa.');
      }
      return;
    }
    await _dio().post('/auth/reset-password', data: {
      'email': email,
      'kode': kode,
      'password_baru': passwordBaru,
      'konfirmasi_password': konfirmasi,
    });
  }
}

class LupaSandiScreen extends StatefulWidget {
  final String? initialEmail;
  const LupaSandiScreen({super.key, this.initialEmail});

  @override
  State<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends State<LupaSandiScreen> {
  final _repo = _PemulihanRepository();

  late final TextEditingController _emailCtrl;
  final _kodeCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfCtrl = TextEditingController();

  int _langkah = 1;
  bool _loading = false;
  bool _lihat = false;
  String? _error;
  int _sisaDetik = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _kodeCtrl.dispose();
    _baruCtrl.dispose();
    _konfCtrl.dispose();
    super.dispose();
  }

  bool _emailValid(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  void _kembali() => Navigator.of(context).maybePop();

  void _mulaiCooldown() {
    _timer?.cancel();
    setState(() => _sisaDetik = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_sisaDetik <= 1) {
        t.cancel();
        setState(() => _sisaDetik = 0);
      } else {
        setState(() => _sisaDetik--);
      }
    });
  }

  Future<void> _kirimKode() async {
    final email = _emailCtrl.text.trim();
    if (!_emailValid(email)) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.kirimKode(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _langkah = 2;
      });
      _mulaiCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _pesanError(e, fallback: 'Gagal mengirim kode. Silakan coba lagi.');
      });
    }
  }

  Future<void> _resetSandi() async {
    if (_kodeCtrl.text.trim().length < 6) {
      setState(() => _error = 'Masukkan 6 digit kode verifikasi.');
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
      await _repo.resetSandi(
        email: _emailCtrl.text.trim(),
        kode: _kodeCtrl.text.trim(),
        passwordBaru: _baruCtrl.text,
        konfirmasi: _konfCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _oranye,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'Kata sandi berhasil diubah. Silakan masuk kembali.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      _kembali();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is DioException
            ? _pesanError(e, fallback: 'Gagal mengatur ulang kata sandi.')
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final langkah1 = _langkah == 1;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: InkWell(
                  onTap: _kembali,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _oranye, width: 1.6),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: _oranye, size: 32),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Atur Ulang Kata Sandi',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          langkah1
                              ? 'Kami akan mengirimkan kode verifikasi\nke email terdaftar Anda:'
                              : 'Kode verifikasi telah dikirim ke\n${_emailCtrl.text.trim()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
                        ),
                        if (!langkah1 && _kPakaiMock) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Mode dummy: gunakan kode $_kKodeDummy',
                            style: TextStyle(color: _oranye, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (langkah1) ..._langkahEmail() else ..._langkahReset(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _merah, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _kembali,
                          child: Text(
                            'Kembali ke Login',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _langkahEmail() {
    return [
      _field(
        controller: _emailCtrl,
        hint: 'Alamat email',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        onSubmitted: (_) => _kirimKode(),
      ),
      const SizedBox(height: 20),
      _tombolUtama(label: 'KIRIM KODE VERIFIKASI', onTap: _kirimKode),
    ];
  }

  List<Widget> _langkahReset() {
    final toggle = IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        _lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 18,
        color: context.textSecondary,
      ),
      onPressed: () => setState(() => _lihat = !_lihat),
    );

    return [
      _field(
        controller: _kodeCtrl,
        hint: 'Kode verifikasi (6 digit)',
        icon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      ),
      const SizedBox(height: 12),
      _field(
        controller: _baruCtrl,
        hint: 'Kata sandi baru (min. 8 karakter)',
        icon: Icons.lock_outline_rounded,
        obscure: !_lihat,
        suffix: toggle,
      ),
      const SizedBox(height: 12),
      _field(
        controller: _konfCtrl,
        hint: 'Konfirmasi kata sandi baru',
        icon: Icons.lock_outline_rounded,
        obscure: !_lihat,
        onSubmitted: (_) => _resetSandi(),
      ),
      const SizedBox(height: 20),
      _tombolUtama(label: 'ATUR ULANG KATA SANDI', onTap: _resetSandi),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: (_sisaDetik == 0 && !_loading) ? _kirimKode : null,
            child: Text(
              _sisaDetik == 0 ? 'Kirim ulang kode' : 'Kirim ulang dalam ${_sisaDetik}s',
              style: TextStyle(
                color: _sisaDetik == 0 ? _oranye : context.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text('•', style: TextStyle(color: context.textMuted)),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _langkah = 1;
                      _error = null;
                      _kodeCtrl.clear();
                      _baruCtrl.clear();
                      _konfCtrl.clear();
                    }),
            child: Text('Ubah email', style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    ];
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        onSubmitted: onSubmitted,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
          border: InputBorder.none,
          prefixIcon: Icon(icon, size: 18, color: _oranye),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _tombolUtama({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: _oranye,
        elevation: 6,
        shadowColor: const Color(0x80FF5520),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _loading ? null : onTap,
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}