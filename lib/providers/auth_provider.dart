import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/token_storage.dart';

part 'auth_provider.g.dart';

/// SESUAIKAN dengan backend
final String _kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api' // Chrome / web
    : 'http://10.0.2.2:3000/api'; // emulator Android

const String _kTokenKey = 'auth_token';

const String _kFlagProfil = 'has_completed_profile';

sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  final String role; // 'klien' | 'pt' | 'admin'
  final bool profileComplete;
  const Authenticated({required this.role, required this.profileComplete});
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() {
    _restoreSession();
    return const Unauthenticated();
  }

  Future<String?> _bacaToken() async {
    final t = await TokenStorage().read();
    if (t != null && t.isNotEmpty) return t;
    return const FlutterSecureStorage().read(key: _kTokenKey);
  }

  Future<void> _restoreSession() async {
    final token = await _bacaToken();
    if (token == null || token.isEmpty) return;

    if (token == 'token_dummy_bugarin' || token.startsWith('oauth_token_')) {
      final flag = await const FlutterSecureStorage().read(key: _kFlagProfil);
      if (state is Authenticated) return;
      state = Authenticated(role: 'klien', profileComplete: flag == 'true');
      return;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _kBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        ),
      );
      final res = await dio.get('/klien/profile');

      Map<String, dynamic> map = {};
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        map = data is Map<String, dynamic> ? data : body;
      }
      final cycle = map['cycle_aktif'] ?? map['progress_cycle'] ?? map['cycle'];
      final lengkap = cycle is Map && map['usia'] != null && map['tinggi_badan'] != null;

      if (state is Authenticated) return; // pengguna sudah login manual lebih dulu
      state = Authenticated(role: 'klien', profileComplete: lengkap);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await logout();
    } catch (_) {}
  }

  void loginSuccess({required String role, required bool profileComplete}) {
    state = Authenticated(role: role, profileComplete: profileComplete);
  }

  void markProfileComplete() {
    final current = state;
    if (current is Authenticated) {
      state = Authenticated(role: current.role, profileComplete: true);
    }
  }

  Future<void> logout() async {
    await TokenStorage().clear();
    const storage = FlutterSecureStorage();
    await storage.delete(key: _kTokenKey);
    await storage.delete(key: _kFlagProfil);
    state = const Unauthenticated();
  }
}