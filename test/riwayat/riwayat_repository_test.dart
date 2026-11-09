import 'package:bugarin_mobile/features/riwayat/data/riwayat_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/fake_http.dart';

DioRiwayatRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioRiwayatRepository(apiClient: api);
}

void main() {
  group('DioRiwayatRepository', () {
    test('getProgressCycles parse list', () async {
      final repo = _repo((options) async {
        expect(options.path, '/klien/progress-cycles');
        return jsonResponse({
          'data': [
            {
              'id': 5,
              'klienId': 1,
              'bbAwalKg': 80,
              'bbTujuanKg': 70,
              'tujuan': 'turun_bb',
              'durasiHari': 60,
              'targetKaloriPerHari': 1800,
              'streak': 4,
              'status': 'aktif',
              'tanggalMulai': '2026-09-01',
              'tanggalSelesai': null,
            }
          ]
        });
      });

      final list = await repo.getProgressCycles();
      expect(list.single.id, 5);
      expect(list.single.isActive, isTrue);
      expect(list.single.targetKaloriPerHari, 1800);
    });

    test('getCycleLogs parse list', () async {
      final repo = _repo((options) async {
        expect(options.path, '/klien/progress-cycles/5/logs');
        return jsonResponse({
          'data': [
            {'tanggal': '2026-09-10', 'kaloriMasuk': 1600, 'kaloriKeluar': 2100},
          ],
          'meta': {'total': 1},
        });
      });

      final logs = await repo.getCycleLogs(5);
      expect(logs.single.tanggal, '2026-09-10');
      expect(logs.single.kaloriMasuk, 1600);
      expect(logs.single.kaloriKeluar, 2100);
    });

    test('getCycleLogs kosong tetap valid', () async {
      final repo = _repo((_) async => jsonResponse({'data': [], 'meta': {'total': 0}}));
      expect(await repo.getCycleLogs(5), isEmpty);
    });

    test('error dipetakan ke ApiException', () async {
      final repo = _repo(
        (_) async => jsonResponse({'error': 'Siklus tidak ditemukan'}, statusCode: 404),
      );
      expect(
        () => repo.getCycleLogs(999),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Siklus'))),
      );
    });
  });
}
