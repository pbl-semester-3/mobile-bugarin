import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/token_storage.dart';
import '../models/klien_profile.dart';

/// Hasil autentikasi: token JWT + role dari backend.
class AuthResult {
  final String token;
  final String role;

  const AuthResult({required this.token, required this.role});
}

/// Error auth yang sudah dipetakan dari response backend.
///
/// [fieldErrors] terisi untuk error validasi Zod backend
/// (`{ "error": { "fields": { "email": ["..."] } } }`).
class AuthException implements Exception {
  final String message;
  final Map<String, List<String>> fieldErrors;

  const AuthException(this.message, {this.fieldErrors = const {}});

  @override
  String toString() => message;
}

/// Kontrak repository auth — memudahkan unit test dengan fake di provider.
abstract interface class AuthRepository {
  Future<AuthResult> register({
    required String nama,
    required String email,
    required String username,
    required String password,
  });

  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  });

  Future<KlienProfile> getProfile();

  Future<void> logout();

  /// Baca token tersimpan (dipakai auth guard saat restore sesi).
  Future<String?> readToken();
}

/// Implementasi nyata yang memanggil backend via [ApiClient].
class DioAuthRepository implements AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  DioAuthRepository({required this.apiClient, required this.tokenStorage});

  @override
  Future<AuthResult> register({
    required String nama,
    required String email,
    required String username,
    required String password,
  }) {
    return _authenticate(() => apiClient.dio.post('/auth/register', data: {
          'nama': nama,
          'email': email,
          'username': username,
          'password': password,
        }));
  }

  @override
  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) {
    return _authenticate(() => apiClient.dio.post('/auth/login', data: {
          'emailOrUsername': emailOrUsername,
          'password': password,
        }));
  }

  @override
  Future<KlienProfile> getProfile() async {
    try {
      final response = await apiClient.dio.get('/klien/profile');
      final data = _unwrapData(response);
      return KlienProfile.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } on DioException {
      // Logout tetap dianggap sukses secara lokal walau backend tak terjangkau.
    } finally {
      await tokenStorage.clear();
    }
  }

  @override
  Future<String?> readToken() => tokenStorage.read();

  Future<AuthResult> _authenticate(Future<Response> Function() request) async {
    try {
      final response = await request();
      final data = _unwrapData(response);
      final token = data['token'] as String?;
      final role = data['role'] as String?;

      if (token == null || role == null) {
        throw const AuthException('Respons server tidak menyertakan token.');
      }

      await tokenStorage.save(token);
      return AuthResult(token: token, role: role);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Map<String, dynamic> _unwrapData(Response response) {
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const AuthException('Respons server tidak valid.');
    }
    return Map<String, dynamic>.from(data);
  }

  AuthException _mapDioException(DioException e) {
    final body = e.response?.data;

    if (body is Map && body['error'] != null) {
      final error = body['error'];

      if (error is Map && error['fields'] is Map) {
        final fieldErrors = (error['fields'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            value is List
                ? value.map((v) => v.toString()).toList()
                : <String>[value.toString()],
          ),
        );
        final first = fieldErrors.values.isEmpty ? null : fieldErrors.values.first;
        return AuthException(
          (first != null && first.isNotEmpty)
              ? first.first
              : 'Data yang dikirim tidak valid.',
          fieldErrors: fieldErrors,
        );
      }

      if (error is String && error.isNotEmpty) {
        return AuthException(error);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AuthException(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    return const AuthException('Terjadi kesalahan pada server. Coba lagi.');
  }
}
