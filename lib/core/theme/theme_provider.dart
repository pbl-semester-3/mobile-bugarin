import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/settings_store.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = SettingsStore.instance.getThemeMode();
    return saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    await SettingsStore.instance.setThemeMode('light');
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;
    await SettingsStore.instance.setThemeMode('dark');
  }
}

final ThemeData bugarinDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0E0E10),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF5C39),
    surface: Color(0xFF201F1F),
    onPrimary: Colors.white,
    onSurface: Color(0xFFFAF8FF),
  ),
  cardColor: const Color(0xFF201F1F),
  dividerColor: const Color(0xFF2A2A2A),
);

final ThemeData bugarinLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F7F5),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF5C39),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Color(0xFF0E1714),
  ),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE2E8E5),
);

extension BugarinThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0E0E10) : const Color(0xFFF4F7F5);
  Color get card => isDark ? const Color(0xFF201F1F) : Colors.white;
  Color get surfaceInner => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDF2EE);
  Color get border => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8E5);
  Color get primary => const Color(0xFFFF5C39);
  Color get textPrimary => isDark ? const Color(0xFFFAF8FF) : const Color(0xFF0E1714);
  Color get textSecondary => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5C6D65);
  Color get textMuted => isDark ? const Color(0x99A1A1AA) : const Color(0xFF8B9B93);
}