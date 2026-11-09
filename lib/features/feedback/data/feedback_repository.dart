import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/api_error.dart';
import '../models/feedback_item.dart';

abstract interface class FeedbackRepository {
  Future<List<FeedbackItem>> getFeedbacks();

  /// Balas feedback PT (1x). Backend menolak 400 untuk feedback AI / sudah dibalas.
  Future<void> replyFeedback(int id, String balasan);

  Future<void> markRead(int id);
}

class DioFeedbackRepository implements FeedbackRepository {
  final ApiClient apiClient;

  DioFeedbackRepository({required this.apiClient});

  @override
  Future<List<FeedbackItem>> getFeedbacks() async {
    try {
      final response = await apiClient.dio.get('/klien/feedbacks');
      final data = response.data is Map ? (response.data as Map)['data'] : null;
      if (data is! List) {
        throw const ApiException('Respons feedback tidak valid.');
      }
      return data
          .whereType<Map>()
          .map((e) => FeedbackItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> replyFeedback(int id, String balasan) async {
    try {
      await apiClient.dio.post('/klien/feedbacks/$id/reply', data: {'balasan': balasan});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markRead(int id) async {
    try {
      await apiClient.dio.put('/klien/feedbacks/$id/read');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
