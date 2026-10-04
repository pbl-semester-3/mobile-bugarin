import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import 'data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _socialLoadingProvider;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Mohon isi semua kolom dengan benar.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).register(
            nama: _nameController.text.trim(),
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      // Munculkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF5520), // Warna Oranye Bugarin
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pendaftaran berhasil! Lengkapi profilmu.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Setelah register, akun sudah terautentikasi → guard arahkan ke Onboarding.
      context.go('/');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mendaftar. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleRegister() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E222B),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Daftar dengan Google belum tersedia.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF14171E),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF2C3240), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 28, offset: Offset(0, 10)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mulai Bersama BUGARIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Langkah awal transformasi kebugaran harianmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.pushReplacement('/login');
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 16, color: Color(0xFF9CA3AF)),
                                    SizedBox(width: 6),
                                    Text('Masuk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5520),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFFFF5520).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_outlined, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Daftar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(hint: 'Nama Lengkap', icon: Icons.badge_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(hint: 'Username', icon: Icons.person_outline_rounded),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(hint: 'Alamat Email', icon: Icons.mail_outline_rounded),
                      validator: (value) => (value == null || !value.contains('@')) ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Kata Sandi',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9CA3AF), size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true, fillColor: const Color(0xFF1E222B),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2C3240))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5520))),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Min. 6 karakter' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5520),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Text('DAFTAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFF2C3240))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.0),
                          child: Text('ATAU DAFTAR DENGAN', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                        ),
                        Expanded(child: Divider(color: Color(0xFF2C3240))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _socialLoadingProvider == 'Google' ? null : _handleGoogleRegister,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E222B),
                          side: const BorderSide(color: Color(0xFF2C3240)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _socialLoadingProvider == 'Google'
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5520)))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleLogoWidget(size: 20),
                                  SizedBox(width: 8),
                                  Text('Google', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true, fillColor: const Color(0xFF1E222B),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2C3240))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5520))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444))),
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