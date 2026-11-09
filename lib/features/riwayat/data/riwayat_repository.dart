import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../../auth/models/progress_cycle.dart';
import '../models/daily_log.dart';

abstract interface class RiwayatRepository {
  Future<List<ProgressCycle>> getProgressCycles();
  Future<List<DailyLogItem>> getCycleLogs(int cycleId);
}

class DioRiwayatRepository implements RiwayatRepository {
  final ApiClient apiClient;

  DioRiwayatRepository({required this.apiClient});

  @override
  Future<List<ProgressCycle>> getProgressCycles() async {
    try {
      final response = await apiClient.dio.get('/klien/progress-cycles');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons siklus tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => ProgressCycle.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<DailyLogItem>> getCycleLogs(int cycleId) async {
    try {
      final response = await apiClient.dio.get('/klien/progress-cycles/$cycleId/logs');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons log siklus tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => DailyLogItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
