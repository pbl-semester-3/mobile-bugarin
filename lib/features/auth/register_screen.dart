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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

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

      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendaftar. Silakan periksa kembali data yang diisi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                border: Border.all(
                  color: const Color(0xFF2C3240),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
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
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Mulai Bersama BUGARIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Langkah awal transformasi kebugaran harianmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
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
                                    Icon(
                                      Icons.login_rounded,
                                      size: 16,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFFF5520),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5520).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
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
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Nama Lengkap',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Username',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username wajib diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Username minimal 3 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Alamat Email',
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Alamat email wajib diisi';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Kata Sandi',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E222B),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2C3240)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF5520), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'DAFTAR SEKARANG',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFF2C3240))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.0),
                          child: Text(
                            'ATAU DAFTAR DENGAN',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFF2C3240))),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2C3240)),
                            ),
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Color(0xFFEA4335),
                                          Color(0xFFFBBC05),
                                          Color(0xFF34A853),
                                          Color(0xFF4285F4),
                                          Color(0xFFEA4335),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E222B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2C3240)),
                            ),
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.apple, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Apple',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.pushReplacement('/login');
                            }
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Color(0xFFFF5520),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E222B),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2C3240)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5520), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}