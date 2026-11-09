import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/api_client_provider.dart';
import '../models/feedback_item.dart';
import 'feedback_repository.dart';

part 'feedback_providers.g.dart';

@riverpod
FeedbackRepository feedbackRepository(Ref ref) {
  return DioFeedbackRepository(apiClient: ref.watch(apiClientProvider));
}

@riverpod
Future<List<FeedbackItem>> feedbackList(Ref ref) {
  return ref.watch(feedbackRepositoryProvider).getFeedbacks();
}
