import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'providers/has_seen_welcome_provider.dart';
import 'router/app_router.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi setting (shared_preferences) + migrasi nilai lama dari
  // flutter_secure_storage (sekali jalan).
  final settings = await SettingsStore.init();
  final hasSeenWelcome = settings.getHasSeenWelcome();

  runApp(
    ProviderScope(
      overrides: [
        hasSeenWelcomeProvider.overrideWith((ref) => hasSeenWelcome),
      ],
      child: const BugarinApp(),
    ),
  );
}

class BugarinApp extends ConsumerWidget {
  const BugarinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Bugarin',
      debugShowCheckedModeBanner: false,
      theme: bugarinLightTheme,
      darkTheme: bugarinDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}