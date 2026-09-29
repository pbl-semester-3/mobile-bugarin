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
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isLoggedIn = authState is Authenticated;

      final isGoingToAuthOrWelcome = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToDashboard = state.matchedLocation == '/';

      // 1. Izinkan akses Onboarding & Dashboard bebas dibuka saat pengujian UI
      if (isGoingToOnboarding || isGoingToDashboard) {
        return null;
      }

      // 2. Cegat rute lain jika memang belum login
      if (!isLoggedIn && !isGoingToAuthOrWelcome) {
        return '/welcome';
      }

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
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
    ],
  );
}