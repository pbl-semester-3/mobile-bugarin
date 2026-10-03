import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/has_seen_welcome_provider.dart';
import '../shell/main_shell.dart';
import 'auth_redirect.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Re-evaluasi redirect saat status auth berubah, tanpa membangun ulang
  // instance GoRouter (menjaga stack navigasi).
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      return resolveAuthRedirect(
        authState: ref.read(authStateProvider),
        hasSeenWelcome: ref.read(hasSeenWelcomeProvider),
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
    ],
  );
}
