import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/master_data.dart';

abstract interface class MasterRepository {
  Future<List<MasterOlahraga>> getOlahraga();
  Future<List<MasterMakanan>> getMakanan({String? q});
}

class DioMasterRepository implements MasterRepository {
  final ApiClient apiClient;

  DioMasterRepository({required this.apiClient});

  @override
  Future<List<MasterOlahraga>> getOlahraga() async {
    try {
      final response = await apiClient.dio.get('/master/olahraga');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons master olahraga tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => MasterOlahraga.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<MasterMakanan>> getMakanan({String? q}) async {
    try {
      final response = await apiClient.dio.get(
        '/master/makanan',
        queryParameters: {if (q != null && q.isNotEmpty) 'q': q},
      );
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons master makanan tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => MasterMakanan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
