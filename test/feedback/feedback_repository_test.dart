import 'package:bugarin_mobile/features/feedback/data/feedback_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/feedback_fixtures.dart';
import '../helpers/fake_http.dart';

DioFeedbackRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioFeedbackRepository(apiClient: api);
}

void main() {
  group('DioFeedbackRepository', () {
    test('getFeedbacks parse AI & PT', () async {
      final repo = _repo((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/klien/feedbacks');
        return jsonResponse({'data': feedbacksFixture, 'meta': {'total': 2}});
      });

      final list = await repo.getFeedbacks();
      expect(list.length, 2);
      expect(list[0].isAi, isTrue);
      expect(list[0].pt, isNull);
      expect(list[1].isPt, isTrue);
      expect(list[1].pt?.nama, 'Sarah');
      expect(list[1].sudahDibalas, isFalse);
    });

    test('replyFeedback mengirim balasan', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/klien/feedbacks/2/reply');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {'id': 2, 'balasanKlien': 'terima kasih'}});
      });

      await repo.replyFeedback(2, 'terima kasih');
      expect(captured!['balasan'], 'terima kasih');
    });

    test('markRead kirim PUT ke /read', () async {
      final repo = _repo((options) async {
        expect(options.method, 'PUT');
        expect(options.path, '/klien/feedbacks/2/read');
        return jsonResponse({'data': {'id': 2, 'dibaca': true}});
      });

      await repo.markRead(2);
    });

    test('reply feedback AI -> 400 dipetakan ke ApiException', () async {
      final repo = _repo(
        (_) async => jsonResponse({'error': 'Feedback dari AI tidak dapat dibalas'}, statusCode: 400),
      );

      expect(
        () => repo.replyFeedback(1, 'halo'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('AI'))),
      );
    });
  });
}
