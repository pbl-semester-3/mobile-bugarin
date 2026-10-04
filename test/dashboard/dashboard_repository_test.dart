import 'package:bugarin_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/fake_http.dart';

DioDashboardRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioDashboardRepository(apiClient: api);
}

void main() {
  group('DioDashboardRepository', () {
    test('getSummary parse lengkap (pt, target, streak, jadwal, reminder, unread)',
        () async {
      final repo = _repo((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/klien/dashboard-summary');
        return jsonResponse({
          'data': {
            'pt': {'id': 3, 'nama': 'Sarah', 'spesialisasi': 'turun_bb'},
            'targetKaloriHariIni': 1662,
            'streak': 5,
            'jadwalMingguan': [
              {'hari': 'Senin', 'jam': '16:30', 'jenis': 'Upper Body', 'lokasi': 'FitZone'},
            ],
            'isReminderActive': true,
            'unreadFeedbackCount': 2,
          }
        });
      });

      final s = await repo.getSummary();

      expect(s.pt?.nama, 'Sarah');
      expect(s.pt?.spesialisasi, 'turun_bb');
      expect(s.targetKaloriHariIni, 1662);
      expect(s.streak, 5);
      expect(s.jadwalMingguan.single.jenis, 'Upper Body');
      expect(s.jadwalMingguan.single.lokasi, 'FitZone');
      expect(s.isReminderActive, isTrue);
      expect(s.unreadFeedbackCount, 2);
    });

    test('getSummary tanpa PT & jadwal kosong', () async {
      final repo = _repo((_) async => jsonResponse({
            'data': {
              'pt': null,
              'targetKaloriHariIni': null,
              'streak': 0,
              'jadwalMingguan': [],
              'isReminderActive': false,
              'unreadFeedbackCount': 0,
            }
          }));

      final s = await repo.getSummary();

      expect(s.pt, isNull);
      expect(s.targetKaloriHariIni, isNull);
      expect(s.jadwalMingguan, isEmpty);
      expect(s.isReminderActive, isFalse);
      expect(s.unreadFeedbackCount, 0);
    });

    test('error dipetakan ke ApiException', () async {
      final repo = _repo(
        (_) async => jsonResponse({'error': 'Unauthorized'}, statusCode: 401),
      );

      expect(() => repo.getSummary(), throwsA(isA<ApiException>()));
    });
  });
}
