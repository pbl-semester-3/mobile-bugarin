import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';

/// Pemulihan kata sandi via kode verifikasi.
///
/// CATATAN: endpoint `/auth/forgot-password` & `/auth/reset-password` **belum
/// ada di backend** — lihat `docs/CATATAN.md`. Sampai backend menyediakannya,
/// pemanggilan akan gagal (404) dan UI menampilkan pesan error yang ramah.
abstract interface class RecoveryRepository {
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String kode,
    required String passwordBaru,
  });
}

class DioRecoveryRepository implements RecoveryRepository {
  final ApiClient apiClient;

  DioRecoveryRepository({required this.apiClient});

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String kode,
    required String passwordBaru,
  }) async {
    try {
      await apiClient.dio.post('/auth/reset-password', data: {
        'email': email,
        'kode': kode,
        'passwordBaru': passwordBaru,
      });
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
