import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';

/// Kontrak repository profil/onboarding klien.
///
/// Dipakai oleh layar Onboarding (Step 1) dan akan dipakai layar Profil
/// (Step 2) untuk update profil, ganti password/tema, dan catat berat badan.
abstract interface class ProfileRepository {
  Future<Map<String, dynamic>> getProfile();

  /// Partial update — field yang tidak dikirim tidak diubah (sesuai backend).
  Future<void> updateProfile({
    String? nama,
    int? usia,
    String? jenisKelamin, // 'pria' | 'wanita'
    String? alergiMakanan,
    double? tinggiBadanCm,
  });

  /// Mulai siklus target baru.
  ///
  /// [bbAwalKg] hanya wajib untuk siklus pertama (belum ada `weight_logs`);
  /// untuk siklus berikutnya backend memakai berat badan terakhir.
  Future<void> startNewCycle({
    required double bbTujuanKg,
    required String tujuan, // 'turun_bb' | 'naik_bb'
    required int durasiHari,
    double? bbAwalKg,
  });
}

class DioProfileRepository implements ProfileRepository {
  final ApiClient apiClient;

  DioProfileRepository({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await apiClient.dio.get('/klien/profile');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! Map) {
        throw const ApiException('Respons profil tidak valid.');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> updateProfile({
    String? nama,
    int? usia,
    String? jenisKelamin,
    String? alergiMakanan,
    double? tinggiBadanCm,
  }) async {
    final body = <String, dynamic>{
      if (nama != null) 'nama': nama,
      if (usia != null) 'usia': usia,
      if (jenisKelamin != null) 'jenisKelamin': jenisKelamin,
      if (alergiMakanan != null) 'alergiMakanan': alergiMakanan,
      if (tinggiBadanCm != null) 'tinggiBadanCm': tinggiBadanCm,
    };

    try {
      await apiClient.dio.put('/klien/profile', data: body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> startNewCycle({
    required double bbTujuanKg,
    required String tujuan,
    required int durasiHari,
    double? bbAwalKg,
  }) async {
    try {
      await apiClient.dio.post('/klien/progress-cycles', data: {
        'bbTujuanKg': bbTujuanKg,
        'tujuan': tujuan,
        'durasiHari': durasiHari,
        if (bbAwalKg != null) 'bbAwalKg': bbAwalKg,
      });
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
