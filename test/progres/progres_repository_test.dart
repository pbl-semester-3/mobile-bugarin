import 'package:bugarin_mobile/features/progres/data/master_repository.dart';
import 'package:bugarin_mobile/features/progres/data/progres_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/fake_http.dart';

ApiClient _api(Future<ResponseBody> Function(RequestOptions options) handler) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return api;
}

void main() {
  group('DioMasterRepository', () {
    test('getOlahraga parse list', () async {
      final repo = DioMasterRepository(apiClient: _api((options) async {
        expect(options.path, '/master/olahraga');
        return jsonResponse({
          'data': [
            {'id': 1, 'nama': 'Jogging', 'metValue': 7.0, 'kategori': 'kardio', 'butuhJarak': true},
            {'id': 4, 'nama': 'Beban', 'metValue': 5.0, 'kategori': 'kekuatan', 'butuhJarak': false},
          ]
        });
      }));

      final list = await repo.getOlahraga();
      expect(list.length, 2);
      expect(list.first.nama, 'Jogging');
      expect(list.first.butuhJarak, isTrue);
      expect(list[1].butuhJarak, isFalse);
    });

    test('getMakanan mengirim query q', () async {
      final repo = DioMasterRepository(apiClient: _api((options) async {
        expect(options.path, '/master/makanan');
        expect(options.queryParameters['q'], 'nasi');
        return jsonResponse({
          'data': [
            {'id': 1, 'nama': 'Nasi Merah', 'kaloriPer100g': 150, 'kategori': 'karbohidrat', 'sumber': 'seed'},
          ]
        });
      }));

      final list = await repo.getMakanan(q: 'nasi');
      expect(list.single.nama, 'Nasi Merah');
      expect(list.single.kaloriPer100g, 150);
    });
  });

  group('DioProgresRepository', () {
    test('createActivityLog payload tanpa jarak bila null', () async {
      Map<String, dynamic>? captured;
      final repo = DioProgresRepository(apiClient: _api((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/klien/activity-logs');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({
          'data': {
            'id': 9,
            'olahragaId': 4,
            'durasiMenit': 45,
            'jarakMeter': null,
            'kaloriTerbakar': 262,
            'tanggal': '2026-10-04',
            'weeklyPlanId': null,
          }
        });
      }));

      final log = await repo.createActivityLog(olahragaId: 4, durasiMenit: 45);
      expect(captured!['olahragaId'], 4);
      expect(captured!.containsKey('jarakMeter'), isFalse);
      expect(log.kaloriTerbakar, 262);
    });

    test('createActivityLog menyertakan jarak bila ada', () async {
      Map<String, dynamic>? captured;
      final repo = DioProgresRepository(apiClient: _api((options) async {
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {'id': 1, 'kaloriTerbakar': 300, 'tanggal': '2026-10-04'}});
      }));

      await repo.createActivityLog(olahragaId: 1, durasiMenit: 30, jarakMeter: 5000);
      expect(captured!['jarakMeter'], 5000);
    });

    test('createMealLog preset kirim makananId', () async {
      Map<String, dynamic>? captured;
      final repo = DioProgresRepository(apiClient: _api((options) async {
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({
          'data': {'id': 2, 'makananId': 1, 'namaMakanan': 'Nasi Merah', 'porsiGram': 150, 'kaloriMasuk': 225, 'tanggal': '2026-10-04'}
        });
      }));

      final log = await repo.createMealLog(makananId: 1, porsiGram: 150);
      expect(captured!['makananId'], 1);
      expect(captured!.containsKey('namaMakanan'), isFalse);
      expect(log.kaloriMasuk, 225);
    });

    test('createMealLog custom kirim namaMakanan', () async {
      Map<String, dynamic>? captured;
      final repo = DioProgresRepository(apiClient: _api((options) async {
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({
          'data': {'id': 3, 'makananId': 99, 'namaMakanan': 'Sushi', 'porsiGram': 200, 'kaloriMasuk': 300, 'tanggal': '2026-10-04'}
        });
      }));

      await repo.createMealLog(namaMakanan: 'Sushi', porsiGram: 200);
      expect(captured!['namaMakanan'], 'Sushi');
      expect(captured!.containsKey('makananId'), isFalse);
    });

    test('getCurrentWeeklyPlan null bila belum ada plan', () async {
      final repo = DioProgresRepository(apiClient: _api((_) async => jsonResponse({'data': null})));
      expect(await repo.getCurrentWeeklyPlan(), isNull);
    });

    test('getCurrentWeeklyPlan parse workout & meal', () async {
      final repo = DioProgresRepository(apiClient: _api((_) async => jsonResponse({
            'data': {
              'id': 5,
              'mingguMulai': '2026-09-29',
              'status': 'disetujui',
              'workoutPlan': [
                {'hari': 'Senin', 'jam': '16:30', 'jenis': 'Upper Body', 'lokasi': 'FitZone'},
              ],
              'mealPlan': [
                {'waktu': 'Siang', 'menu': 'Nasi + Ayam', 'estimasiKalori': 600},
              ],
            }
          })));

      final plan = await repo.getCurrentWeeklyPlan();
      expect(plan!.status, 'disetujui');
      expect(plan.workoutPlan.single.jenis, 'Upper Body');
      expect(plan.mealPlan.single.estimasiKalori, 600);
    });

    test('error dipetakan ke ApiException', () async {
      final repo = DioProgresRepository(
        apiClient: _api((_) async => jsonResponse({'error': 'Berat badan belum tercatat'}, statusCode: 422)),
      );
      expect(
        () => repo.createActivityLog(olahragaId: 4, durasiMenit: 30),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Berat badan'))),
      );
    });
  });
}
