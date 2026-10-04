import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/weekly_plan.dart';

abstract interface class ProgresRepository {
  Future<CreatedActivityLog> createActivityLog({
    required int olahragaId,
    required int durasiMenit,
    double? jarakMeter,
  });

  /// Satu request = satu item makanan. Kirim `makananId` (preset) atau
  /// `namaMakanan` (custom → backend estimasi AI bila belum ada di master).
  Future<CreatedMealLog> createMealLog({
    int? makananId,
    String? namaMakanan,
    required double porsiGram,
  });

  Future<WeeklyPlan?> getCurrentWeeklyPlan();
}

class DioProgresRepository implements ProgresRepository {
  final ApiClient apiClient;

  DioProgresRepository({required this.apiClient});

  @override
  Future<CreatedActivityLog> createActivityLog({
    required int olahragaId,
    required int durasiMenit,
    double? jarakMeter,
  }) async {
    try {
      final response = await apiClient.dio.post('/klien/activity-logs', data: {
        'olahragaId': olahragaId,
        'durasiMenit': durasiMenit,
        if (jarakMeter != null) 'jarakMeter': jarakMeter,
      });
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! Map) {
        throw const ApiException('Respons log olahraga tidak valid.');
      }
      return CreatedActivityLog.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<CreatedMealLog> createMealLog({
    int? makananId,
    String? namaMakanan,
    required double porsiGram,
  }) async {
    try {
      final response = await apiClient.dio.post('/klien/meal-logs', data: {
        if (makananId != null) 'makananId': makananId,
        if (namaMakanan != null && namaMakanan.isNotEmpty) 'namaMakanan': namaMakanan,
        'porsiGram': porsiGram,
      });
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! Map) {
        throw const ApiException('Respons log makan tidak valid.');
      }
      return CreatedMealLog.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<WeeklyPlan?> getCurrentWeeklyPlan() async {
    try {
      final response = await apiClient.dio.get('/klien/weekly-plan/current');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data == null) return null;
      if (data is! Map) {
        throw const ApiException('Respons weekly plan tidak valid.');
      }
      return WeeklyPlan.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
