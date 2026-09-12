---
name: gorouter-navigation-bugarin
description: Struktur navigasi GoRouter untuk Mobile Klien Bugarin — auth guard reaktif, bottom navigation shell, dan alur onboarding profil. Gunakan saat setup routing atau menambah screen baru.
metadata:
  origin: bugarin-project
  adapted_from: ECC dart-flutter-patterns (MIT license, https://github.com/affaan-m/ECC)
---

# GoRouter Navigation (Bugarin Mobile)

Rujuk `Bugarin_PRD_Mobile.md` bab 2 untuk struktur navigasi lengkap: Login/Register → cek profil lengkap → Onboarding (kalau perlu) → MainShell (5 tab bottom nav + Profil terpisah).

## Activation

- Setup routing awal project.
- Menambah screen baru ke bottom nav atau alur onboarding.
- Auth guard tidak redirect dengan benar (mis. user login tapi masih diarahkan ke `/login`).

## Setup

```yaml
dependencies:
  go_router: ^14.0.0
```

## Auth Guard Reaktif (redirect berdasar state, bukan dicek sekali di awal)

```dart
// router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState is Authenticated;
      final isProfileComplete = authState is Authenticated && authState.profileComplete;
      final loc = state.matchedLocation;

      if (!isLoggedIn) {
        return loc == '/login' || loc == '/register' ? null : '/login';
      }
      if (isLoggedIn && !isProfileComplete && loc != '/onboarding') {
        return '/onboarding'; // paksa lengkapi profil sebelum akses fitur lain
      }
      if (isLoggedIn && isProfileComplete && (loc == '/login' || loc == '/onboarding')) {
        return '/'; // sudah lengkap, jangan biarkan balik ke onboarding/login
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
      GoRoute(path: '/profil', builder: (_, __) => const ProfilScreen()), // di luar shell, ikon terpisah
    ],
  );
});
```

**Kenapa `refreshListenable`, bukan cek sekali di `initState`**: status auth/profil bisa berubah *setelah* app sudah render (mis. user baru selesai isi Onboarding, atau token invalid di tengah sesi karena 401 dari interceptor Dio). Redirect harus re-evaluasi otomatis setiap `authStateProvider` berubah, bukan cuma dicek sekali saat pertama buka app.

## ShellRoute untuk Bottom Navigation

`ShellRoute` menjaga `MainShell` (bottom nav bar) tetap ada dan tidak rebuild ulang saat pindah antar 5 tab — cuma bagian `child`-nya yang berganti:

```dart
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  static const _tabs = ['/', '/pt-ku', '/progres', '/riwayat', '/feedback'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabs.indexOf(GoRouterState.of(context).matchedLocation);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'PT ku'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Progres'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Feedback'),
        ],
      ),
    );
  }
}
```

Profil **sengaja di luar** `ShellRoute` (bukan tab ke-6) karena aksesnya lewat ikon terpisah di pojok atas tiap screen, sesuai wireframe — bukan bagian bottom navigation.

## Navigasi ke Onboarding Ulang (Mulai Target Baru)

Banner "Mulai Target Baru" di Profil (lihat `Bugarin_PRD_Mobile.md` bab 3.8) membuka ulang form yang sama seperti Onboarding — **push**, bukan **go**, supaya tombol back Android tetap bisa kembali ke Profil (beda dengan Onboarding pertama kali yang memang tidak boleh di-back karena profil belum lengkap):

```dart
// Dari Profil, saat cycle status = 'selesai':
ElevatedButton(
  onPressed: () => context.push('/onboarding?mode=new-cycle'),
  child: const Text('🎉 Mulai Target Baru'),
)
```

Bedakan lewat query param `mode` di `OnboardingScreen` untuk menentukan apakah ini pengisian pertama kali (tidak bisa di-back, tidak ada tombol close) atau siklus baru (bisa di-back ke Profil).

## Anti-Patterns

| Anti-Pattern | Risiko | Perbaikan |
|---|---|---|
| Cek auth cuma sekali di `initState`/splash screen | Tidak re-evaluasi saat token expired di tengah sesi (401 dari interceptor) | `redirect` reaktif dengan `refreshListenable` |
| Semua screen (termasuk Profil) dimasukkan ke `ShellRoute` bottom nav | Profil jadi tab ke-6, tidak sesuai desain (harusnya ikon terpisah) | Taruh `/profil` sebagai route mandiri di luar `ShellRoute` |
| `context.go()` untuk alur "Mulai Target Baru" | Tombol back hilang, padahal ini bukan first-time onboarding | `context.push()` supaya bisa kembali ke Profil |
| Bottom nav index dihitung manual dengan state terpisah dari router | Bisa desync dari URL yang sebenarnya aktif | Derive index dari `GoRouterState.of(context).matchedLocation` |

## Related

- Skill: `flutter-riverpod-patterns` — `authStateProvider` yang menggerakkan redirect di atas
- Skill: `dio-jwt-networking` — pemicu redirect ke `/login` saat 401
