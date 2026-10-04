import 'package:dio/dio.dart';

/// Error API yang sudah dipetakan dari response backend.
///
/// Dipakai bersama oleh seluruh repository (auth, profil, progres, dst).
/// [fieldErrors] terisi untuk error validasi Zod backend
/// (`{ "error": { "fields": { "email": ["..."] } } }`).
class ApiException implements Exception {
  final String message;
  final Map<String, List<String>> fieldErrors;

  const ApiException(this.message, {this.fieldErrors = const {}});

  @override
  String toString() => message;
}

/// Memetakan [DioException] menjadi [ApiException] dengan pesan yang ramah.
///
/// - AppError backend → `{ "error": "pesan" }`
/// - Validasi Zod → `{ "error": { "fields": { ... } } }` (mengisi [ApiException.fieldErrors])
/// - Timeout/koneksi → pesan jaringan generik
ApiException mapDioException(DioException e) {
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
      return ApiException(
        (first != null && first.isNotEmpty)
            ? first.first
            : 'Data yang dikirim tidak valid.',
        fieldErrors: fieldErrors,
      );
    }

    if (error is String && error.isNotEmpty) {
      return ApiException(error);
    }
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError) {
    return const ApiException(
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
    );
  }

  return const ApiException('Terjadi kesalahan pada server. Coba lagi.');
}
