import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/pt_models.dart';

abstract interface class PtRepository {
  Future<List<PtRecommendation>> getRecommendations();

  /// Kirim request ke PT; backend mengembalikan status `pending`.
  Future<void> sendPairingRequest(int ptId);

  /// `null` bila klien belum pernah mengirim request.
  Future<PairingRequest?> getCurrentRequest();
}

class DioPtRepository implements PtRepository {
  final ApiClient apiClient;

  DioPtRepository({required this.apiClient});

  @override
  Future<List<PtRecommendation>> getRecommendations() async {
    try {
      final response = await apiClient.dio.get('/pt/recommendations');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons rekomendasi PT tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => PtRecommendation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> sendPairingRequest(int ptId) async {
    try {
      await apiClient.dio.post('/klien/pairing-requests', data: {'ptId': ptId});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PairingRequest?> getCurrentRequest() async {
    try {
      final response = await apiClient.dio.get('/klien/pairing-requests/current');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data == null) return null;
      if (data is! Map) {
        throw const ApiException('Respons status PT tidak valid.');
      }
      return PairingRequest.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
