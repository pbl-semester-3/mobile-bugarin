import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';
import 'lupa_sandi_screen.dart';

// ============================================================================
// KONFIGURASI
// ============================================================================

/// true  = pakai data dummy (tanpa backend). UBAH KE false SAAT BACKEND SIAP.
const bool _kPakaiMock = true;

/// SESUAIKAN dengan backend.
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

/// Key ini sama dengan yang dipakai kode login sebelumnya.
const String _kTokenKey = 'auth_token';

const Color _oranye = Color(0xFFFF5520);
const Color _merahError = Color(0xFFEF4444);

// ============================================================================
// DATA: API + DUMMY
// ============================================================================

class _KredensialSalah implements Exception {
  const _KredensialSalah();
}

class _HasilLogin {
  final String token;
  final String? nama;
  final String role;
  const _HasilLogin({required this.token, this.nama, this.role = 'klien'});
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
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['message'] is String) return first['message'] as String;
        if (first is String) return first;
      }
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

Map<String, dynamic> _unwrapMap(dynamic body) {
  if (body is Map<String, dynamic>) {
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
  return <String, dynamic>{};
}

class _AuthRepository {
  static const _storage = FlutterSecureStorage();

  /// POST /auth/login  -> JWT
  Future<_HasilLogin> login(String identifier, String password) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      // Aturan dummy (sama seperti sebelumnya): kata sandi < 6 karakter dianggap salah.
      if (password.length < 6) throw const _KredensialSalah();
      final nama = identifier.contains('@') ? identifier.split('@').first : identifier;
      return _HasilLogin(token: 'token_dummy_bugarin', nama: nama, role: 'klien');
    }

    try {
      final res = await _buatDio().post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      final map = _unwrapMap(res.data);
      final token = (map['token'] ?? map['access_token'] ?? map['jwt'])?.toString();
      if (token == null || token.isEmpty) {
        throw StateError('Token tidak ditemukan pada respons login.');
      }
      final user = map['user'];
      final nama = user is Map ? (user['nama'] ?? user['name'])?.toString() : null;
      final role = (user is Map ? user['role'] : null) ?? map['role'] ?? 'klien';
      return _HasilLogin(token: token, nama: nama, role: role.toString());
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 404) throw const _KredensialSalah();
      rethrow;
    }
  }

  /// POST /auth/register  (klien)
  Future<void> register({
    required String nama,
    required String email,
    required String username,
    required String password,
    required String konfirmasi,
  }) async {
    if (_kPakaiMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return;
    }
    await _buatDio().post('/auth/register', data: {
      'nama': nama,
      'email': email,
      'username': username,
      'password': password,
      'konfirmasi_password': konfirmasi,
    });
  }

  /// Aturan AuthGate (PRD 2): profil lengkap (usia, tinggi) DAN punya siklus aktif.
  /// Dipanggil setelah token tersimpan. Jika gagal, dianggap belum lengkap.
  Future<bool> profilLengkap() async {
    if (_kPakaiMock) {
      return (await _storage.read(key: 'has_completed_profile')) == 'true';
    }
    try {
      final res = await _buatDio().get('/klien/profile');
      final map = _unwrapMap(res.data);
      final cycle = map['cycle_aktif'] ?? map['progress_cycle'] ?? map['cycle'];
      return cycle is Map && map['usia'] != null && map['tinggi_badan'] != null;
    } catch (_) {
      return false;
    }
  }
}

// ============================================================================
// LAYAR
// ============================================================================

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsLogin;
  const LoginScreen({super.key, this.initialIsLogin = true});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _repo = _AuthRepository();
  late bool _isLoginTab;

  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage; // error pendaftaran / umum
  bool _hasLoginError = false; // kredensial login salah
  String? _socialLoadingProvider;

  @override
  void initState() {
    super.initState();
    _isLoginTab = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  /// Menghapus pesan error saat pengguna mulai mengetik lagi.
  void _clearErrors(String _) {
    if (_hasLoginError || _errorMessage != null) {
      setState(() {
        _hasLoginError = false;
        _errorMessage = null;
      });
    }
  }

  void _gantiTab(bool login) {
    setState(() {
      _isLoginTab = login;
      _hasLoginError = false;
      _errorMessage = null;
    });
  }

  void _snack(String pesan, {bool sukses = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: sukses ? _oranye : _merahError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(sukses ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pesan,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
  }

  /// Simpan penanda lokal lalu arahkan sesuai AuthGate:
  /// profil lengkap -> beranda, selain itu -> onboarding.
  Future<void> _arahkanSetelahMasuk(String role) async {
    final lengkap = await _repo.profilLengkap();
    if (lengkap) {
      await _storage.write(key: 'has_completed_profile', value: 'true');
    } else {
      await _storage.delete(key: 'has_completed_profile');
    }
    if (!mounted) return;
    // Beritahu router: status login + apakah profil sudah lengkap.
    ref.read(authStateProvider.notifier).loginSuccess(role: role, profileComplete: lengkap);
    context.go(lengkap ? '/' : '/onboarding');
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _hasLoginError = false;
    });

    if (_isLoginTab) {
      await _login();
    } else {
      await _register();
    }
  }

  Future<void> _login() async {
    final id = _loginIdentifierController.text.trim();
    final pw = _loginPasswordController.text;

    if (id.isEmpty || pw.isEmpty) {
      setState(() => _errorMessage = 'Email/username dan kata sandi wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final hasil = await _repo.login(id, pw);

      // Aplikasi mobile hanya untuk klien (PRD).
      if (hasil.role != 'klien') {
        if (mounted) {
          setState(() => _errorMessage = 'Aplikasi ini khusus untuk akun klien.');
        }
        return;
      }

      await _storage.write(key: _kTokenKey, value: hasil.token);
      if (hasil.nama != null && hasil.nama!.isNotEmpty) {
        await _storage.write(key: 'user_name', value: hasil.nama!);
      }
      await _arahkanSetelahMasuk(hasil.role);
    } on _KredensialSalah {
      if (mounted) setState(() => _hasLoginError = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _pesanError(e, fallback: 'Gagal masuk. Silakan coba lagi.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final nama = _registerNameController.text.trim();
    final username = _registerUsernameController.text.trim();
    final email = _registerEmailController.text.trim();
    final pw = _registerPasswordController.text;
    final konf = _registerConfirmController.text;

    String? pesan;
    if (nama.isEmpty || username.isEmpty || email.isEmpty || pw.isEmpty || konf.isEmpty) {
      pesan = 'Semua kolom pendaftaran wajib diisi.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      pesan = 'Format email tidak valid.';
    } else if (pw.length < 8) {
      pesan = 'Kata sandi minimal 8 karakter.';
    } else if (pw != konf) {
      pesan = 'Konfirmasi kata sandi tidak sama.';
    }
    if (pesan != null) {
      setState(() => _errorMessage = pesan);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.register(
        nama: nama,
        email: email,
        username: username,
        password: pw,
        konfirmasi: konf,
      );
      if (!mounted) return;

      setState(() {
        _isLoginTab = true;
        _loginIdentifierController.text = email; // memudahkan login pertama
        _loginPasswordController.clear();
        _registerNameController.clear();
        _registerUsernameController.clear();
        _registerEmailController.clear();
        _registerPasswordController.clear();
        _registerConfirmController.clear();
      });
      _snack('Pendaftaran berhasil! Silakan login.');
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _pesanError(e, fallback: 'Gagal mendaftar. Silakan coba lagi.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Langsung membuka halaman Atur Ulang Kata Sandi.
  void _bukaLupaSandi() {
    final id = _loginIdentifierController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LupaSandiScreen(initialEmail: id.contains('@') ? id : null),
      ),
    );
  }

  Future<void> _handleSocialAuth(String provider) async {
    if (_socialLoadingProvider != null || _isLoading) return;

    // Login Google tidak ada di PRD (auth = email/username + password, JWT).
    if (!_kPakaiMock) {
      _snack('Masuk dengan $provider belum tersedia.', sukses: false);
      return;
    }

    setState(() => _socialLoadingProvider = provider);
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      final socialUserName = provider == 'Google' ? 'Alex Rivera' : 'Member';
      await _storage.write(key: 'user_name', value: socialUserName);
      await _storage.write(key: _kTokenKey, value: 'oauth_token_${provider.toLowerCase()}_dummy');
      await _arahkanSetelahMasuk('klien');
    } catch (err) {
      if (mounted) setState(() => _errorMessage = 'Gagal masuk dengan $provider');
    } finally {
      if (mounted) setState(() => _socialLoadingProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const accentColor = _oranye;
    const errorColor = _merahError;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: EdgeInsets.fromLTRB(22, 16, 22, 28 + bottomInset),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: context.isDark ? Colors.black54 : const Color(0x1F000000),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoginTab ? 'Selamat Datang Kembali' : 'Mulai Bersama BUGARIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginTab
                        ? 'Capai performa puncak fisik & ritme latihanmu'
                        : 'Langkah awal transformasi kebugaran harianmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSwitchTab(
                              'Masuk', Icons.login_rounded, _isLoginTab, () => _gantiTab(true)),
                        ),
                        Expanded(
                          child: _buildSwitchTab('Daftar', Icons.person_add_alt_1_rounded,
                              !_isLoginTab, () => _gantiTab(false)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifikasi error atas (daftar / error server / kolom kosong)
                  if (_errorMessage != null && !_hasLoginError) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFFCA5A5), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isLoginTab) ...[
                    _buildTextField(
                      _loginIdentifierController,
                      'Email atau username',
                      Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      isError: _hasLoginError,
                      onChanged: _clearErrors,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _loginPasswordController,
                      'Kata Sandi',
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      isError: _hasLoginError,
                      onChanged: _clearErrors,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),

                    if (_hasLoginError) ...[
                      const SizedBox(height: 10),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2, left: 4),
                            child: Icon(Icons.warning_amber_rounded, color: errorColor, size: 16),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Email/username atau kata sandi yang Anda masukkan salah. '
                              'Silakan coba lagi atau atur ulang kata sandi Anda.',
                              style: TextStyle(
                                color: errorColor,
                                fontSize: 11,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _bukaLupaSandi,
                        child: const Text(
                          'Lupa Kata Sandi?',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildTextField(_registerNameController, 'Nama Lengkap', Icons.badge_outlined,
                        onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _registerUsernameController, 'Username', Icons.person_outline_rounded,
                        onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _registerEmailController, 'Alamat Email', Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress, onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _registerPasswordController,
                      'Kata Sandi (min. 8 karakter)',
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onChanged: _clearErrors,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _registerConfirmController,
                      'Konfirmasi Kata Sandi',
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onChanged: _clearErrors,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLoginTab ? 'MASUK SEKARANG' : 'DAFTAR SEKARANG',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(child: Divider(color: context.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'ATAU',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SocialAuthCard(
                    label: 'Google',
                    customIcon: const _GoogleLogoWidget(size: 20),
                    isLoading: _socialLoadingProvider == 'Google',
                    onTap: () => _handleSocialAuth('Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTab(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _oranye : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    bool isError = false,
    Function(String)? onChanged,
  }) {
    final borderColor = isError ? _merahError.withValues(alpha: 0.8) : context.border;
    final iconColor = isError ? _merahError : context.textSecondary;
    final bgColor = isError ? _merahError.withValues(alpha: 0.05) : context.surfaceInner;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isError ? 1.2 : 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: iconColor, size: 19),
          suffixIcon: isPassword
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isError) ...[
                      const Icon(Icons.error_outline_rounded, color: _merahError, size: 18),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: context.textSecondary,
                        size: 19,
                      ),
                      onPressed: onToggleVisibility,
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class SocialAuthCard extends StatelessWidget {
  final String label;
  final Widget customIcon;
  final bool isLoading;
  final VoidCallback onTap;

  const SocialAuthCard({
    super.key,
    required this.label,
    required this.customIcon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _oranye.withValues(alpha: 0.2),
        highlightColor: context.textPrimary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _oranye),
                )
              else ...[
                customIcon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoWidget extends StatelessWidget {
  final double size;
  const _GoogleLogoWidget({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final pBlue = Path()..moveTo(23.745, 12.27)..relativeCubicTo(0, -0.7, -0.06, -1.4, -0.19, -2.07)..lineTo(12, 10.2)..lineTo(12, 14.71)..lineTo(18.6, 14.71)..relativeCubicTo(-0.29, 1.52, -1.14, 2.82, -2.4, 3.68)..relativeLineTo(0, 3.05)..relativeLineTo(3.88, 0)..relativeCubicTo(2.27, -2.09, 3.66, -5.17, 3.66, -9.17)..close();
    canvas.drawPath(pBlue, Paint()..color = const Color(0xFF4285F4));

    final pGreen = Path()..moveTo(12, 24)..relativeCubicTo(3.24, 0, 5.95, -1.08, 7.93, -2.91)..relativeLineTo(-3.88, -3.05)..relativeCubicTo(-1.08, 0.72, -2.45, 1.16, -4.05, 1.16)..relativeCubicTo(-3.12, 0, -5.77, -2.1, -6.72, -4.94)..lineTo(1.28, 14.26)..relativeLineTo(0, 3.13)..cubicTo(3.26, 21.36, 7.34, 24, 12, 24)..close();
    canvas.drawPath(pGreen, Paint()..color = const Color(0xFF34A853));

    final pYellow = Path()..moveTo(5.28, 14.26)..relativeCubicTo(-0.25, -0.72, -0.38, -1.49, -0.38, -2.26)..relativeCubicTo(0, -0.77, 0.13, -1.54, 0.38, -2.26)..lineTo(5.28, 6.61)..lineTo(1.28, 6.61)..cubicTo(0.46, 8.23, 0, 10.06, 0, 12)..cubicTo(0, 13.94, 0.46, 15.77, 1.28, 17.39)..lineTo(5.28, 14.26)..close();
    canvas.drawPath(pYellow, Paint()..color = const Color(0xFFFBBC05));

    final pRed = Path()..moveTo(12, 4.75)..relativeCubicTo(1.77, 0, 3.35, 0.61, 4.6, 1.8)..relativeLineTo(3.42, -3.42)..cubicTo(17.95, 1.19, 15.24, 0, 12, 0)..cubicTo(7.34, 0, 3.26, 2.64, 1.28, 6.61)..lineTo(5.28, 9.74)..cubicTo(6.23, 6.9, 8.88, 4.75, 12, 4.75)..close();
    canvas.drawPath(pRed, Paint()..color = const Color(0xFFEA4335));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}