import 'package:bugarin_mobile/features/pt_ku/data/pt_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/fake_http.dart';

DioPtRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioPtRepository(apiClient: api);
}

void main() {
  group('DioPtRepository', () {
    test('getRecommendations parse list', () async {
      final repo = _repo((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/pt/recommendations');
        return jsonResponse({
          'data': [
            {'id': 3, 'nama': 'Sarah', 'spesialisasi': 'turun_bb', 'tempatGym': 'FitZone'},
          ],
          'meta': {'total': 1},
        });
      });

      final list = await repo.getRecommendations();
      expect(list.single.nama, 'Sarah');
      expect(list.single.tempatGym, 'FitZone');
    });

    test('sendPairingRequest mengirim ptId', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/klien/pairing-requests');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {'id': 1, 'status': 'pending', 'createdAt': '2026-10-04'}});
      });

      await repo.sendPairingRequest(3);
      expect(captured!['ptId'], 3);
    });

    test('getCurrentRequest null bila belum ada', () async {
      final repo = _repo((options) async {
        expect(options.path, '/klien/pairing-requests/current');
        return jsonResponse({'data': null});
      });
      expect(await repo.getCurrentRequest(), isNull);
    });

    test('getCurrentRequest parse pending + pt', () async {
      final repo = _repo((_) async => jsonResponse({
            'data': {
              'id': 7,
              'status': 'pending',
              'alasanPenolakan': null,
              'createdAt': '2026-10-04T05:00:00.000Z',
              'pt': {'id': 3, 'nama': 'Sarah', 'spesialisasi': 'turun_bb', 'tempatGym': 'FitZone'},
            }
          }));

      final req = await repo.getCurrentRequest();
      expect(req!.isPending, isTrue);
      expect(req.pt?.nama, 'Sarah');
      expect(req.alasanPenolakan, isNull);
    });

    test('getCurrentRequest parse ditolak + alasan', () async {
      final repo = _repo((_) async => jsonResponse({
            'data': {
              'id': 8,
              'status': 'ditolak',
              'alasanPenolakan': 'Sedang penuh',
              'createdAt': '2026-10-04T05:00:00.000Z',
              'pt': {'id': 4, 'nama': 'Alex', 'spesialisasi': 'naik_bb', 'tempatGym': null},
            }
          }));

      final req = await repo.getCurrentRequest();
      expect(req!.isDitolak, isTrue);
      expect(req.alasanPenolakan, 'Sedang penuh');
    });

    test('422 lengkapi profil dipetakan ke ApiException', () async {
      final repo = _repo((_) async => jsonResponse(
            {'error': 'Lengkapi profil dan buat siklus target terlebih dahulu'},
            statusCode: 422,
          ));

      expect(
        () => repo.getRecommendations(),
        throwsA(isA<ApiException>().having(
          (e) => e.message.toLowerCase(),
          'message',
          contains('lengkapi profil'),
        )),
      );
    });
  });
}
