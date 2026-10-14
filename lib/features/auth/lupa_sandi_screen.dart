import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/api_error.dart';
import 'data/recovery_repository_provider.dart';

const Color _oranye = Color(0xFFFF5C39);
const Color _merah = Color(0xFFE53935);

/// Alur Lupa Kata Sandi: kirim kode verifikasi ke email → verifikasi kode +
/// set kata sandi baru. Dipakai dari `LoginScreen`.
class LupaSandiScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const LupaSandiScreen({super.key, this.initialEmail});

  @override
  ConsumerState<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends ConsumerState<LupaSandiScreen> {
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
      await ref.read(recoveryRepositoryProvider).forgotPassword(email);
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
        _error = e is ApiException ? e.message : 'Gagal mengirim kode. Silakan coba lagi.';
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
      await ref.read(recoveryRepositoryProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            kode: _kodeCtrl.text.trim(),
            passwordBaru: _baruCtrl.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: _oranye,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Kata sandi berhasil diubah. Silakan masuk kembali.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Gagal mengatur ulang kata sandi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langkah1 = _langkah == 1;

    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _kembali,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: context.surfaceInner, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _oranye, width: 1.6)),
                child: const Icon(Icons.lock_reset_rounded, color: _oranye, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Atur Ulang Kata Sandi',
                  style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                langkah1
                    ? 'Kami akan mengirimkan kode verifikasi ke email terdaftar Anda:'
                    : 'Kode verifikasi telah dikirim ke ${_emailCtrl.text.trim()}',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 22),
              if (langkah1) ...[
                _inputBox(controller: _emailCtrl, hint: 'Alamat Email', icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress, enabled: true),
              ] else ...[
                _inputBox(controller: _kodeCtrl, hint: 'Kode Verifikasi (6 digit)',
                    icon: Icons.pin_outlined, keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    enabled: true),
                const SizedBox(height: 12),
                _inputBox(controller: _baruCtrl, hint: 'Kata Sandi Baru (min. 8)',
                    icon: Icons.lock_outline_rounded, obscure: !_lihat, enabled: true,
                    suffix: IconButton(
                      icon: Icon(_lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18, color: context.textSecondary),
                      onPressed: () => setState(() => _lihat = !_lihat),
                    )),
                const SizedBox(height: 12),
                _inputBox(controller: _konfCtrl, hint: 'Konfirmasi Kata Sandi Baru',
                    icon: Icons.lock_outline_rounded, obscure: !_lihat, enabled: true),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1, left: 2),
                      child: Icon(Icons.warning_amber_rounded, color: _merah, size: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: _merah, fontSize: 12, height: 1.4)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : (langkah1 ? _kirimKode : _resetSandi),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _oranye,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(langkah1 ? 'KIRIM KODE VERIFIKASI' : 'SIMPAN KATA SANDI',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                ),
              ),
              if (!langkah1) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _sisaDetik > 0 ? null : _kirimKode,
                  child: Text(
                    _sisaDetik > 0 ? 'Kirim ulang dalam ${_sisaDetik}s' : 'Kirim ulang kode',
                    style: TextStyle(
                      color: _sisaDetik > 0 ? context.textMuted : _oranye,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: context.textSecondary, size: 19),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}
