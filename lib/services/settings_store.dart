import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan setting/preferensi non-rahasia memakai `shared_preferences`.
///
/// Rahasia (mis. token JWT) TETAP di `flutter_secure_storage` — lihat
/// `token_storage.dart`. Store ini menangani: mode tema & flag welcome.
class SettingsStore {
  SettingsStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'app_theme_mode';
  static const _hasSeenWelcomeKey = 'has_seen_welcome';
  static const _migratedKey = 'settings_migrated_v1';

  static SettingsStore? _instance;

  /// Wajib dipanggil sekali di `main()` sebelum `runApp`.
  static Future<SettingsStore> init() async {
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore._(prefs);
    await store._migrateOnce();
    _instance = store;
    return store;
  }

  static SettingsStore get instance {
    final store = _instance;
    if (store == null) {
      throw StateError(
        'SettingsStore belum diinisialisasi. Panggil SettingsStore.init() di main().',
      );
    }
    return store;
  }

  /// Migrasi sekali jalan: pindahkan nilai setting lama dari
  /// `flutter_secure_storage` (versi sebelum memakai shared_preferences),
  /// lalu hapus key lama agar tidak jadi data yatim.
  Future<void> _migrateOnce() async {
    if (_prefs.getBool(_migratedKey) ?? false) return;

    const secure = FlutterSecureStorage();

    final theme = await secure.read(key: _themeKey);
    if (theme != null && !_prefs.containsKey(_themeKey)) {
      await _prefs.setString(_themeKey, theme);
    }

    final welcome = await secure.read(key: _hasSeenWelcomeKey);
    if (welcome != null && !_prefs.containsKey(_hasSeenWelcomeKey)) {
      await _prefs.setBool(_hasSeenWelcomeKey, welcome == 'true');
    }

    await secure.delete(key: _themeKey);
    await secure.delete(key: _hasSeenWelcomeKey);

    await _prefs.setBool(_migratedKey, true);
  }

  /// 'light' | 'dark' | null (belum pernah diset).
  String? getThemeMode() => _prefs.getString(_themeKey);

  Future<void> setThemeMode(String value) => _prefs.setString(_themeKey, value);

  bool getHasSeenWelcome() => _prefs.getBool(_hasSeenWelcomeKey) ?? false;

  Future<void> setHasSeenWelcome() => _prefs.setBool(_hasSeenWelcomeKey, true);
}
