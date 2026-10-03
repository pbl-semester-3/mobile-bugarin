import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/has_seen_welcome_provider.dart';
import '../../services/token_storage.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _sheetAnimationController;
  double _dragOffsetY = 0.0;

  bool _isBgLoaded = false;
  static const _bgAsset = AssetImage('assets/images/bg_welcome.jpg');

  @override
  void initState() {
    super.initState();
    _markWelcomeSeen();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _sheetAnimationController = BottomSheet.createAnimationController(this);
    _sheetAnimationController.duration = const Duration(milliseconds: 380);
    _sheetAnimationController.reverseDuration = const Duration(milliseconds: 260);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_bgAsset, context).then((_) {
      if (mounted && !_isBgLoaded) {
        setState(() => _isBgLoaded = true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  // Welcome hanya untuk pembukaan app pertama kali — tandai sudah dibuka
  // supaya pembukaan berikutnya langsung ke Login (lihat auth guard).
  void _markWelcomeSeen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(hasSeenWelcomeProvider.notifier).state = true;
      TokenStorage().setHasSeenWelcome();
    });
  }

  void _openAuthSheet({required bool isLogin}) {
    setState(() => _dragOffsetY = 0.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionAnimationController: _sheetAnimationController,
      builder: (context) => LoginScreen(initialIsLogin: isLogin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        child: !_isBgLoaded
            ? Center(
                key: const ValueKey('splash_loading'),
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.card,
                    border: Border.all(color: context.border, width: 2),
                  ),
                  child: const Center(
                    child: Text('B', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFFF5520))),
                  ),
                ),
              )
            : GestureDetector(
                key: const ValueKey('welcome_content'),
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < 0) {
                    setState(() => _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(-70.0, 0.0));
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
                    // Gambar Latar
                    Positioned.fill(
                      child: Image(
                        image: _bgAsset,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Container(color: context.bg),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.8, 1.0],
                            colors: isDark
                                ? [
                                    const Color(0xFF090E0C).withValues(alpha: 0.3),
                                    const Color(0xFF090E0C).withValues(alpha: 0.65),
                                    const Color(0xFF090E0C).withValues(alpha: 0.95),
                                    const Color(0xFF090E0C),
                                  ]
                                : [
                                    const Color(0xFFF4F7F5).withValues(alpha: 0.2),
                                    const Color(0xFFF4F7F5).withValues(alpha: 0.6),
                                    const Color(0xFFF4F7F5).withValues(alpha: 0.92),
                                    const Color(0xFFF4F7F5),
                                  ],
                          ),
                        ),
                      ),
                    ),
                    // Konten Utama
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),
                            // Logo B
                            Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.card,
                                  border: Border.all(color: context.border, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black45 : const Color(0xFFE2E8E5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
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
                                        border: Border.all(color: const Color(0xFFFF5520).withValues(alpha: 0.4), width: 1.5),
                                      ),
                                    ),
                                    const Text('B', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFFF5520))),
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
                                color: context.textPrimary,
                                letterSpacing: 8.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MULAI EVOLUSI FISIKMU',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                                letterSpacing: 3.5,
                              ),
                            ),
                            const Spacer(flex: 4),
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
                                    setState(() => _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(-70.0, 0.0));
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
                                    color: const Color(0xFFFF5520), // Oranye Solid
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x40FF5520), blurRadius: 18, offset: Offset(0, 6)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                        child: const Icon(Icons.north_east_rounded, color: Color(0xFFFF5520), size: 22),
                                      ),
                                      const Expanded(
                                        child: Center(
                                          child: Text(
                                            'GESER KE ATAS  UNTUK MULAI',
                                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                                          ),
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
                                    Text('Sudah punya akun? ', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                    GestureDetector(
                                      onTap: () => _openAuthSheet(isLogin: false),
                                      child: const Text('Masuk', style: TextStyle(color: Color(0xFFFF5520), fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: Color(0xFFFF5520)),
                                    const SizedBox(width: 6),
                                    Text('v2.4 Pro', style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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