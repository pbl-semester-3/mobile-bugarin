import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _sheetAnimationController;

  double _dragOffsetY = 0.0;
  
  // Status penanda apakah gambar HD sudah selesai dimuat 100% ke memori
  bool _isBgLoaded = false;
  static const _bgAsset = AssetImage('assets/images/bg_welcome.jpg');

  @override
  void initState() {
    super.initState();

    // Animasi tombol mengambang
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Controller modal bottom sheet
    _sheetAnimationController = BottomSheet.createAnimationController(this);
    _sheetAnimationController.duration = const Duration(milliseconds: 380);
    _sheetAnimationController.reverseDuration = const Duration(milliseconds: 260);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tunggu gambar HD selesai dimuat ke memori, baru buka layarnya
    precacheImage(_bgAsset, context).then((_) {
      if (mounted && !_isBgLoaded) {
        setState(() {
          _isBgLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  void _openAuthSheet({required bool isLogin}) {
    setState(() => _dragOffsetY = 0.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionAnimationController: _sheetAnimationController,
      builder: (context) => LoginScreen(initialIsLogin: isLogin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        child: !_isBgLoaded
            // 1. TAMPILAN SPLASH ELEGAN (Hanya muncul sekejap ~0.3 detik saat memuat gambar HD)
            ? Center(
                key: const ValueKey('splash_loading'),
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF161920),
                    border: Border.all(color: const Color(0xFF2C3240), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF5520),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              )
            // 2. TAMPILAN WELCOME UTUH (Muncul bersamaan dengan gambar HD tanpa delay belang)
            : GestureDetector(
                key: const ValueKey('welcome_content'),
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < 0) {
                    setState(() {
                      _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(-70.0, 0.0);
                    });
                  }
                },
                onVerticalDragEnd: (details) {
                  if (_dragOffsetY < -20 || (details.primaryVelocity ?? 0) < -100) {
                    _openAuthSheet(isLogin: true);
                  } else {
                    setState(() => _dragOffsetY = 0.0);
                  }
                },
                child: Stack(
                  children: [
                    // Gambar HD Asli
                    Positioned.fill(
                      child: Image(
                        image: _bgAsset,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: const Color(0xFF0D0F14));
                        },
                      ),
                    ),

                    // Gradasi Maskulin Solid
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.8, 1.0],
                            colors: [
                              const Color(0xFF0D0F14).withValues(alpha: 0.35),
                              const Color(0xFF0D0F14).withValues(alpha: 0.6),
                              const Color(0xFF0D0F14).withValues(alpha: 0.92),
                              const Color(0xFF0D0F14),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Konten Utama
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),

                            // Logo
                            Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF161920),
                                  border: Border.all(
                                    color: const Color(0xFF2C3240),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 66,
                                      height: 66,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFF5520).withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'B',
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF5520),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            Text(
                              'BUGARIN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 56,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                                letterSpacing: 8.0,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'MULAI EVOLUSI FISIKMU',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 3.5,
                              ),
                            ),

                            const Spacer(flex: 4),

                            // Tombol Geser Interaktif
                            AnimatedBuilder(
                              animation: _bounceController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _dragOffsetY + _bounceAnimation.value),
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                onTap: () => _openAuthSheet(isLogin: true),
                                onVerticalDragUpdate: (details) {
                                  if (details.primaryDelta != null && details.primaryDelta! < 0) {
                                    setState(() {
                                      _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(-70.0, 0.0);
                                    });
                                  }
                                },
                                onVerticalDragEnd: (details) {
                                  if (_dragOffsetY < -20 || (details.primaryVelocity ?? 0) < -100) {
                                    _openAuthSheet(isLogin: true);
                                  } else {
                                    setState(() => _dragOffsetY = 0.0);
                                  }
                                },
                                child: Container(
                                  height: 64,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161920),
                                    borderRadius: BorderRadius.circular(36),
                                    border: Border.all(
                                      color: const Color(0xFF2C3240),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 18,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFF5520),
                                        ),
                                        child: const Icon(
                                          Icons.north_east_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'GESER KE ATAS',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 2.2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.north_east_rounded,
                                              color: Color(0xFFFF5520),
                                              size: 15,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 46),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Sudah punya akun? ',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _openAuthSheet(isLogin: true),
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Color(0xFFFF5520),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Color(0xFFFF5520),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'v2.4 Pro',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}