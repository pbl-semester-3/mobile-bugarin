import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../providers/auth_provider.dart';
import '../shell/main_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final lokasi = state.matchedLocation;

      final halamanPublik =
          lokasi == '/welcome' || lokasi == '/login' || lokasi == '/register';

      if (auth is! Authenticated) {
        return halamanPublik ? null : '/welcome';
      }

      if (!auth.profileComplete) {
        return lokasi == '/onboarding' ? null : '/onboarding';
      }

      if (halamanPublik) return '/';

      return null;
    },
    routes: [
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
        // /onboarding?mode=new-cycle dipakai dari Profil untuk memulai siklus baru.
        builder: (context, state) => OnboardingScreen(
          mode: state.uri.queryParameters['mode'] ?? 'first-time',
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}