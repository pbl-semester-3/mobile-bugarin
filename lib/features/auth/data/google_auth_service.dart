import 'package:google_sign_in/google_sign_in.dart';

/// Abstraksi Google Sign-In supaya logika login bisa diuji tanpa SDK platform.
abstract interface class GoogleAuthService {
  /// true bila `GOOGLE_CLIENT_ID` sudah dikonfigurasi.
  bool get isConfigured;

  /// Jalankan sign-in interaktif. Mengembalikan `idToken` Google, atau `null`
  /// bila user membatalkan. Melempar exception untuk error lain.
  Future<String?> signInAndGetIdToken();
}

class GoogleAuthServiceImpl implements GoogleAuthService {
  GoogleAuthServiceImpl({required this.serverClientId});

  /// Web client ID (sama dengan `GOOGLE_CLIENT_ID` backend) — dipakai sebagai
  /// `serverClientId` agar `idToken.aud` cocok dengan audience backend.
  final String serverClientId;

  bool _initialized = false;

  @override
  bool get isConfigured => serverClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  @override
  Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) {
      throw StateError('GOOGLE_CLIENT_ID belum di-set.');
    }
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('ID token Google tidak tersedia.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // Dibatalkan / UI tidak tersedia → perlakukan sebagai "tidak jadi login".
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      rethrow;
    }
  }
}
