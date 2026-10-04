import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';
import 'data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsLogin;
  const LoginScreen({super.key, this.initialIsLogin = true});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isLoginTab;
  
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage; // Untuk error pendaftaran / umum
  bool _hasLoginError = false; // Khusus trigger UI error di kolom login
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

  // Fungsi untuk menghapus error saat user mulai mengetik lagi
  void _clearErrors(String _) {
    if (_hasLoginError || _errorMessage != null) {
      setState(() {
        _hasLoginError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasLoginError = false;
    });

    try {
      final notifier = ref.read(authStateProvider.notifier);

      if (!_isLoginTab) {
        // --- LOGIKA REGISTER ---
        final nama = _registerNameController.text.trim();
        final username = _registerUsernameController.text.trim();
        final email = _registerEmailController.text.trim();
        final password = _registerPasswordController.text;

        // Validasi klien diselaraskan dengan registerSchema backend (Zod).
        if (nama.length < 2) {
          setState(() => _errorMessage = 'Nama minimal 2 karakter.');
          return;
        }
        if (username.length < 3) {
          setState(() => _errorMessage = 'Username minimal 3 karakter.');
          return;
        }
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
          setState(() => _errorMessage = 'Format email tidak valid.');
          return;
        }
        if (password.length < 8) {
          setState(() => _errorMessage = 'Kata sandi minimal 8 karakter.');
          return;
        }

        await notifier.register(
          nama: nama,
          email: email,
          username: username,
          password: password,
        );

        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop(); // tutup bottom sheet
        if (mounted) context.go('/');

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF5520),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Pendaftaran berhasil! Lengkapi profilmu.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        );
      } else {
        // --- LOGIKA LOGIN ---
        if (_loginIdentifierController.text.isEmpty ||
            _loginPasswordController.text.isEmpty) {
          setState(() => _hasLoginError = true);
          return;
        }

        await notifier.login(
          emailOrUsername: _loginIdentifierController.text.trim(),
          password: _loginPasswordController.text,
        );

        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop(); // tutup bottom sheet
        if (mounted) context.go('/');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (_isLoginTab) {
        // Pesan salah kredensial tampil di bawah kolom (UI teman).
        setState(() => _hasLoginError = true);
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Terjadi kesalahan sistem. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog Lupa Kata Sandi
  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController();
    bool isSending = false;
    const accentOrange = Color(0xFFFF5520);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: dialogContext.card, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentOrange.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentOrange.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: dialogContext.surfaceInner, shape: BoxShape.circle),
                          child: Icon(Icons.close_rounded, color: dialogContext.textSecondary, size: 16),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentOrange, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: accentOrange, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Atur Ulang Kata Sandi',
                      style: TextStyle(color: dialogContext.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kami akan mengirimkan kode verifikasi atau tautan\npemulihan ke email terdaftar Anda:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dialogContext.textSecondary, fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: dialogContext.surfaceInner,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dialogContext.border),
                      ),
                      child: TextField(
                        controller: emailResetController,
                        style: TextStyle(color: dialogContext.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'atlet.prima@bugarin.id',
                          hintStyle: TextStyle(color: dialogContext.textMuted),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: accentOrange, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                setDialogState(() => isSending = true);
                                await Future.delayed(const Duration(seconds: 1)); 
                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);
                                
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    backgroundColor: accentOrange,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Tautan pemulihan berhasil dikirim ke ${emailResetController.text.isEmpty ? "email Anda" : emailResetController.text}.', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: accentOrange.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('KIRIM TAUTAN PEMULIHAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Text('Kembali ke Login', style: TextStyle(color: dialogContext.textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Social auth belum punya backend OAuth — tampilkan pesan jelas, jangan
  // menulis token dummy (menjaga sesi auth tetap bersih).
  void _handleSocialAuth(String provider) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.surfaceInner,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Masuk dengan $provider belum tersedia.',
          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const accentColor = Color(0xFFFF5520);
    const errorColor = Color(0xFFEF4444);

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
                  BoxShadow(color: context.isDark ? Colors.black54 : const Color(0x1F000000), blurRadius: 30, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 4,
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
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border)
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSwitchTab('Masuk', Icons.login_rounded, _isLoginTab, () {
                          setState(() { _isLoginTab = true; _clearErrors(''); });
                        })),
                        Expanded(child: _buildSwitchTab('Daftar', Icons.person_add_alt_1_rounded, !_isLoginTab, () {
                          setState(() { _isLoginTab = false; _clearErrors(''); });
                        })),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifikasi Error Atas (Hanya untuk daftar atau error server)
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
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
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
                      isError: _hasLoginError, // Beri efek merah jika error
                      onChanged: _clearErrors,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _loginPasswordController, 
                      'Kata Sandi', 
                      Icons.lock_outline_rounded,
                      isPassword: true, 
                      obscureText: _obscurePassword,
                      isError: _hasLoginError, // Beri efek merah jika error
                      onChanged: _clearErrors,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)
                    ),
                    
                    // Munculkan Pesan Error di Bawah Kolom Kata Sandi
                    if (_hasLoginError) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, left: 4),
                            child: Icon(Icons.warning_amber_rounded, color: errorColor, size: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Kata sandi yang Anda masukkan salah. Silakan coba lagi\natau atur ulang kata sandi Anda.',
                              style: TextStyle(color: errorColor, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog, 
                        child: const Text('Lupa Kata Sandi?', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    _buildTextField(_registerNameController, 'Nama Lengkap', Icons.badge_outlined, onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(_registerUsernameController, 'Username', Icons.person_outline_rounded, onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(_registerEmailController, 'Alamat Email', Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, onChanged: _clearErrors),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _registerPasswordController, 'Kata Sandi', Icons.lock_outline_rounded,
                      isPassword: true, obscureText: _obscurePassword,
                      onChanged: _clearErrors,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)
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
          color: isSelected ? const Color(0xFFFF5520) : Colors.transparent,
          borderRadius: BorderRadius.circular(20)
        ),
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
    final borderColor = isError ? const Color(0xFFEF4444).withValues(alpha: 0.8) : context.border;
    final iconColor = isError ? const Color(0xFFEF4444) : context.textSecondary;
    final bgColor = isError ? const Color(0xFFEF4444).withValues(alpha: 0.05) : context.surfaceInner;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isError ? 1.2 : 1.0)
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
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.textSecondary, size: 19),
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
        splashColor: const Color(0xFFFF5520).withValues(alpha: 0.2),
        highlightColor: context.textPrimary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.1)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5520)))
              else ...[
                customIcon,
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ]
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