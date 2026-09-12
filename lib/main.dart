import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: BugarinApp()));
}

class BugarinApp extends ConsumerWidget {
  const BugarinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Bugarin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      // TODO: themeMode dikontrol dari data profil (siang/malam), bukan system,
      // sesuai keputusan tech stack — ganti ThemeMode.system setelah provider tema ada.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
