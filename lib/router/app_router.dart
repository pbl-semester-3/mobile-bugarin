import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_provider.dart';
import '../shell/main_shell.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/pt_ku/pt_ku_screen.dart';
import '../features/progres/progres_screen.dart';
import '../features/riwayat/riwayat_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/profil/profil_screen.dart';

part 'app_router.g.dart';

/// Jembatan Riverpod state -> Listenable yang dibutuhkan GoRouter `refreshListenable`.
/// Auth guard WAJIB reaktif (bukan dicek sekali di awal) karena status auth bisa
/// berubah di tengah sesi (401 dari interceptor Dio, atau onboarding baru selesai).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateNotifierProvider, (_, __) => notifyListeners());
  }
}

@riverpod
GoRouter router(Ref ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateNotifierProvider);
      final loc = state.matchedLocation;

      if (authState is Unauthenticated) {
        return (loc == '/login' || loc == '/register') ? null : '/login';
      }

      final authenticated = authState as Authenticated;
      if (!authenticated.profileComplete && loc != '/onboarding') {
        return '/onboarding';
      }
      if (authenticated.profileComplete && (loc == '/login' || loc == '/onboarding')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/pt-ku', builder: (_, __) => const PtKuScreen()),
          GoRoute(path: '/progres', builder: (_, __) => const ProgresScreen()),
          GoRoute(path: '/riwayat', builder: (_, __) => const RiwayatScreen()),
          GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
        ],
      ),
      GoRoute(path: '/profil', builder: (_, __) => const ProfilScreen()),
    ],
  );
}
