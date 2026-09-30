import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsLogin;
  const LoginScreen({super.key, this.initialIsLogin = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  late bool _isLoginTab;

  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
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
    super.dispose();
  }

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
      
      if (!mounted) return;
      context.go('/onboarding');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFEF4444), content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialAuth(String provider) async {
    if (_socialLoadingProvider != null || _isLoading) return;
    setState(() => _socialLoadingProvider = provider);
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      final socialUserName = provider == 'Google' ? 'Alex Rivera' : 'Apple Member';
      await _storage.write(key: 'user_name', value: socialUserName);
      await _storage.write(key: 'auth_token', value: 'oauth_token_${provider.toLowerCase()}_active');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.surfaceInner,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF3EE5B4), size: 20),
              const SizedBox(width: 10),
              Text(
                'Berhasil terhubung dengan $provider!',
                style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      context.go('/onboarding');
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFEF4444), content: Text('Gagal masuk dengan $provider: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _socialLoadingProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const accentColor = Color(0xFFFF5520);

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
                      decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoginTab ? 'Selamat Datang Kembali' : 'Mulai Bersama BUGARIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginTab ? 'Capai performa puncak fisik & ritme latihanmu' : 'Langkah awal transformasi kebugaran harianmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(24), border: Border.all(color: context.border)),
                    child: Row(
                      children: [
                        Expanded(child: _buildSwitchTab('Masuk', Icons.login_rounded, _isLoginTab, () => setState(() => _isLoginTab = true))),
                        Expanded(child: _buildSwitchTab('Daftar', Icons.person_add_alt_1_rounded, !_isLoginTab, () => setState(() => _isLoginTab = false))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoginTab) ...[
                    _buildTextField(_loginIdentifierController, 'Email atau username', Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(_loginPasswordController, 'Kata Sandi', Icons.lock_outline_rounded, isPassword: true, obscureText: _obscurePassword, onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tautan reset kata sandi telah dikirim ke email.'))),
                        child: const Text('Lupa Kata Sandi?', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    _buildTextField(_registerNameController, 'Nama Lengkap', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(_registerUsernameController, 'Username', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(_registerEmailController, 'Alamat Email', Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(_registerPasswordController, 'Kata Sandi', Icons.lock_outline_rounded, isPassword: true, obscureText: _obscurePassword, onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)),
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
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isLoginTab ? 'MASUK SEKARANG' : 'DAFTAR SEKARANG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
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
                        child: Text('ATAU', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                      Expanded(child: Divider(color: context.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _SocialAuthCard(label: 'Google', customIcon: const _GoogleLogoWidget(size: 20), isLoading: _socialLoadingProvider == 'Google', onTap: () => _handleSocialAuth('Google'))),
                      const SizedBox(width: 12),
                      Expanded(child: _SocialAuthCard(label: 'Apple', customIcon: Icon(Icons.apple, color: context.textPrimary, size: 22), isLoading: _socialLoadingProvider == 'Apple', onTap: () => _handleSocialAuth('Apple'))),
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

  Widget _buildSwitchTab(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF5520) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : context.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: context.textSecondary, size: 19),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.textSecondary, size: 19), onPressed: onToggleVisibility)
              : null,
        ),
      ),
    );
  }
}

class _SocialAuthCard extends StatelessWidget {
  final String label;
  final Widget customIcon;
  final bool isLoading;
  final VoidCallback onTap;

  const _SocialAuthCard({required this.label, required this.customIcon, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFFF5520).withValues(alpha: 0.2),
        highlightColor: context.textPrimary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border, width: 1.1)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3EE5B4)))
              else ...[
                customIcon,
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
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