import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsLogin;

  const LoginScreen({
    super.key,
    this.initialIsLogin = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();

  late bool _isLoginTab;

  // Controller formulir dalam kondisi kosong murni
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _socialLoadingProvider; // Menyimpan provider sosial yang sedang diproses ('Google' atau 'Apple')

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
    super.dispose();
  }

  // 1. ALUR SUBMIT EMAIL & PASSWORD
  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      String userName = 'Sobat Bugarin';
      if (!_isLoginTab && _registerNameController.text.trim().isNotEmpty) {
        userName = _registerNameController.text.trim();
      } else if (_isLoginTab && _loginIdentifierController.text.trim().isNotEmpty) {
        final id = _loginIdentifierController.text.trim();
        userName = id.contains('@') ? id.split('@').first : id;
      }

      await _storage.write(key: 'user_name', value: userName);
      await _storage.write(key: 'auth_token', value: 'token_email_bugarin_dummy');

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Terjadi kesalahan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. ALUR LOGIN DENGAN GOOGLE / APPLE (INTERAKTIF & SIAP PAKAI)
  Future<void> _handleSocialAuth(String provider) async {
    if (_socialLoadingProvider != null || _isLoading) return;

    setState(() => _socialLoadingProvider = provider);

    try {
      /*
        CATATAN UNTUK PENGEMBANGAN INTEGRASI BACKEND:
        Jika sudah memasang package `google_sign_in` atau `sign_in_with_apple`,
        kamu cukup memanggil API OAuth di sini:
        
        final GoogleSignInAccount? account = await GoogleSignIn().signIn();
        final auth = await account?.authentication;
        // Kirim auth.idToken ke API backend Bugarin via Dio:
        // final res = await ref.read(apiClientProvider).post('/auth/google', data: {'token': auth?.idToken});
      */

      // Simulasi jeda autentikasi akun Google/Apple seperti aplikasi sungguhan
      await Future.delayed(const Duration(milliseconds: 1200));

      final socialUserName = provider == 'Google' ? 'Alex Rivera' : 'Apple Member';
      await _storage.write(key: 'user_name', value: socialUserName);
      await _storage.write(key: 'auth_token', value: 'oauth_token_${provider.toLowerCase()}_active');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16251F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF3EE5B4), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Berhasil terhubung dengan $provider!',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        // Arahkan ke Onboarding untuk setup target kalori dan fisik
        context.go('/onboarding');
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Gagal masuk dengan $provider:$err'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _socialLoadingProvider = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E0C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF12161F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF1F2635), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3448),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Judul & Subtitle
                  Text(
                    _isLoginTab ? 'Selamat Datang Kembali' : 'Mulai Bersama BUGARIN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
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
                    style: const TextStyle(
                      color: Color(0xFF8F9E98),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Segmented Switcher Masuk / Daftar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171C27),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF242C3E)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSwitchTab(
                            title: 'Masuk',
                            icon: Icons.login_rounded,
                            isSelected: _isLoginTab,
                            onTap: () => setState(() => _isLoginTab = true),
                          ),
                        ),
                        Expanded(
                          child: _buildSwitchTab(
                            title: 'Daftar',
                            icon: Icons.person_add_alt_1_rounded,
                            isSelected: !_isLoginTab,
                            onTap: () => setState(() => _isLoginTab = false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FORMULIR INPUT
                  if (_isLoginTab) ...[
                    _buildTextField(
                      controller: _loginIdentifierController,
                      hintText: 'Email atau username',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _loginPasswordController,
                      hintText: 'Kata Sandi',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tautan reset kata sandi telah dikirim ke email.')),
                          );
                        },
                        child: const Text(
                          'Lupa Kata Sandi?',
                          style: TextStyle(
                            color: Color(0xFFFF5520),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _registerNameController,
                      hintText: 'Nama Lengkap',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _registerUsernameController,
                      hintText: 'Username',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _registerEmailController,
                      hintText: 'Alamat Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _registerPasswordController,
                      hintText: 'Kata Sandi',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // TOMBOL AKSI UTAMA
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5520),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
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

                  // GARIS PEMISAH "ATAU"
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFF222938), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'ATAU',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFF222938), thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // TOMBOL LOGIN SOSIAL (GOOGLE & APPLE VEKTOR INTERAKTIF)
                  Row(
                    children: [
                      // Tombol Google
                      Expanded(
                        child: _SocialAuthCard(
                          label: 'Google',
                          customIcon: const GoogleLogoWidget(size: 20),
                          isLoading: _socialLoadingProvider == 'Google',
                          onTap: () => _handleSocialAuth('Google'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Apple
                      Expanded(
                        child: _SocialAuthCard(
                          label: 'Apple',
                          customIcon: const Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 22,
                          ),
                          isLoading: _socialLoadingProvider == 'Apple',
                          onTap: () => _handleSocialAuth('Apple'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5520) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF8F9E98),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8F9E98),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222836)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF5A6678), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF8F9E98), size: 19),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8F9E98),
                    size: 19,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// WIDGET KARTU TOMBOL SOSIAL DENGAN EFEK RIPPLE & INDIKATOR LOADING
class _SocialAuthCard extends StatelessWidget {
  final String label;
  final Widget customIcon;
  final bool isLoading;
  final VoidCallback onTap;

  const _SocialAuthCard({
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
        splashColor: const Color(0xFFFF5520).withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF171C27),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF242C3E), width: 1.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3EE5B4),
                  ),
                )
              else ...[
                customIcon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
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

// LOGO VEKTOR RESMI GOOGLE 4 WARNA (MURNI CANVAS FLUTTER - BEBAS CORS & OFFLINE-READY)
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Biru (#4285F4)
    final pBlue = Path()
      ..moveTo(23.745, 12.27)
      ..relativeCubicTo(0, -0.7, -0.06, -1.4, -0.19, -2.07)
      ..lineTo(12, 10.2)
      ..lineTo(12, 14.71)
      ..lineTo(18.6, 14.71)
      ..relativeCubicTo(-0.29, 1.52, -1.14, 2.82, -2.4, 3.68)
      ..relativeLineTo(0, 3.05)
      ..relativeLineTo(3.88, 0)
      ..relativeCubicTo(2.27, -2.09, 3.66, -5.17, 3.66, -9.17)
      ..close();
    canvas.drawPath(pBlue, Paint()..color = const Color(0xFF4285F4));

    // 2. Hijau (#34A853)
    final pGreen = Path()
      ..moveTo(12, 24)
      ..relativeCubicTo(3.24, 0, 5.95, -1.08, 7.93, -2.91)
      ..relativeLineTo(-3.88, -3.05)
      ..relativeCubicTo(-1.08, 0.72, -2.45, 1.16, -4.05, 1.16)
      ..relativeCubicTo(-3.12, 0, -5.77, -2.1, -6.72, -4.94)
      ..lineTo(1.28, 14.26)
      ..relativeLineTo(0, 3.13)
      ..cubicTo(3.26, 21.36, 7.34, 24, 12, 24)
      ..close();
    canvas.drawPath(pGreen, Paint()..color = const Color(0xFF34A853));

    // 3. Kuning (#FBBC05)
    final pYellow = Path()
      ..moveTo(5.28, 14.26)
      ..relativeCubicTo(-0.25, -0.72, -0.38, -1.49, -0.38, -2.26)
      ..relativeCubicTo(0, -0.77, 0.13, -1.54, 0.38, -2.26)
      ..lineTo(5.28, 6.61)
      ..lineTo(1.28, 6.61)
      ..cubicTo(0.46, 8.23, 0, 10.06, 0, 12)
      ..cubicTo(0, 13.94, 0.46, 15.77, 1.28, 17.39)
      ..lineTo(5.28, 14.26)
      ..close();
    canvas.drawPath(pYellow, Paint()..color = const Color(0xFFFBBC05));

    // 4. Merah (#EA4335)
    final pRed = Path()
      ..moveTo(12, 4.75)
      ..relativeCubicTo(1.77, 0, 3.35, 0.61, 4.6, 1.8)
      ..relativeLineTo(3.42, -3.42)
      ..cubicTo(17.95, 1.19, 15.24, 0, 12, 0)
      ..cubicTo(7.34, 0, 3.26, 2.64, 1.28, 6.61)
      ..lineTo(5.28, 9.74)
      ..cubicTo(6.23, 6.9, 8.88, 4.75, 12, 4.75)
      ..close();
    canvas.drawPath(pRed, Paint()..color = const Color(0xFFEA4335));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}