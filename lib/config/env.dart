class Env {
  // Diisi lewat: flutter run --dart-define=API_URL=http://10.0.2.2:4000
  // Default fallback ke alias localhost Android emulator kalau tidak di-set.
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
}
