import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/weekly_plan.dart';

abstract interface class ProgresRepository {
  Future<CreatedActivityLog> createActivityLog({
    required int olahragaId,
    int? durasiMenit,
    double? jarakMeter,
    double? beratBebanKg,
    int? jumlahSet,
    int? repetisi,
    int? waktuIstirahatDetik,
  });

  Future<List<CreatedActivityLog>> getActivityLogs({String? tanggal});

  /// Satu request = satu item makanan. Kirim `makananId` (preset) atau
  /// `namaMakanan` (custom → backend estimasi AI bila belum ada di master).
  Future<CreatedMealLog> createMealLog({
    int? makananId,
    String? namaMakanan,
    required double porsiGram,
  });

  /// Estimasi kalori makanan tanpa menyimpan (dipakai saat menambah draft menu).
  Future<EstimateMakanan> estimateMakanan(String namaMakanan);

  Future<WeeklyPlan?> getCurrentWeeklyPlan();
}

class DioProgresRepository implements ProgresRepository {
  final ApiClient apiClient;

  DioProgresRepository({required this.apiClient});

  @override
  Future<CreatedActivityLog> createActivityLog({
    required int olahragaId,
    int? durasiMenit,
    double? jarakMeter,
    double? beratBebanKg,
    int? jumlahSet,
    int? repetisi,
    int? waktuIstirahatDetik,
  }) async {
    try {
      final response = await apiClient.dio.post('/klien/activity-logs', data: {
        'olahragaId': olahragaId,
        if (durasiMenit != null) 'durasiMenit': durasiMenit,
        if (jarakMeter != null) 'jarakMeter': jarakMeter,
        if (beratBebanKg != null) 'beratBebanKg': beratBebanKg,
        if (jumlahSet != null) 'jumlahSet': jumlahSet,
        if (repetisi != null) 'repetisi': repetisi,
        if (waktuIstirahatDetik != null) 'waktuIstirahatDetik': waktuIstirahatDetik,
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
  Future<List<CreatedActivityLog>> getActivityLogs({String? tanggal}) async {
    try {
      final response = await apiClient.dio.get(
        '/klien/activity-logs',
        queryParameters: {
          if (tanggal != null && tanggal.isNotEmpty) 'tanggal': tanggal,
        },
      );
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons riwayat olahraga tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => CreatedActivityLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
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
  Future<EstimateMakanan> estimateMakanan(String namaMakanan) async {
    try {
      final response = await apiClient.dio.post('/klien/meal-logs/estimate', data: {
        'namaMakanan': namaMakanan,
      });
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! Map) {
        throw const ApiException('Respons estimasi makanan tidak valid.');
      }
      return EstimateMakanan.fromJson(Map<String, dynamic>.from(data));
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
