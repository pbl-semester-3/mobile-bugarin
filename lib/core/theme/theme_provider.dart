import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.read(key: _themeKey);
    if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    await _storage.write(key: _themeKey, value: 'light');
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _storage.write(key: _themeKey, value: 'dark');
  }
}

final ThemeData bugarinDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF090E0C),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF5520),
    surface: Color(0xFF0F1C18),
    onPrimary: Colors.white,
    onSurface: Colors.white,
  ),
  cardColor: const Color(0xFF0F1C18),
  dividerColor: const Color(0xFF1B2F28),
);

final ThemeData bugarinLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F7F5),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF5520),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Color(0xFF0E1714),
  ),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE2E8E5),
);

extension BugarinThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF090E0C) : const Color(0xFFF4F7F5);
  Color get card => isDark ? const Color(0xFF0F1C18) : Colors.white;
  Color get surfaceInner => isDark ? const Color(0xFF14241F) : const Color(0xFFEDF2EE);
  Color get border => isDark ? const Color(0xFF1B2F28) : const Color(0xFFE2E8E5);
  Color get primary => const Color(0xFFFF5520);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0E1714);
  Color get textSecondary => isDark ? const Color(0xFF8A9992) : const Color(0xFF5C6D65);
  Color get textMuted => isDark ? const Color(0xFF5A6B64) : const Color(0xFF8B9B93);
}