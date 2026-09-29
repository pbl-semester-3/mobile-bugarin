import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/has_seen_welcome_provider.dart';
import 'router/app_router.dart';
import 'services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasSeenWelcome = await TokenStorage().getHasSeenWelcome();

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
    
    return MaterialApp.router(
      title: 'Bugarin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}