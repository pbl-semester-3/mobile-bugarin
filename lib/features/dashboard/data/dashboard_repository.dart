import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary();
}

class DioDashboardRepository implements DashboardRepository {
  final ApiClient apiClient;

  DioDashboardRepository({required this.apiClient});

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final response = await apiClient.dio.get('/klien/dashboard-summary');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! Map) {
        throw const ApiException('Respons dashboard tidak valid.');
      }
      return DashboardSummary.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
