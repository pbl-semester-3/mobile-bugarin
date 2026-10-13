class Env {
  // Diisi lewat: flutter run --dart-define=API_URL=http://10.0.2.2:4000
  // Default fallback ke alias localhost Android emulator kalau tidak di-set.
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  // Google OAuth (Web client ID) — WAJIB diisi saat run agar login Google aktif:
  //   flutter run --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  // Dipakai sebagai `serverClientId` di GoogleSignIn agar `idToken.aud`
  // cocok dengan audience yang diverifikasi backend (GOOGLE_CLIENT_ID backend).
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  static bool get hasGoogleClientId => googleClientId.isNotEmpty;
}
