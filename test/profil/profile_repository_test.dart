import 'package:bugarin_mobile/features/profil/data/profile_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../helpers/fake_http.dart';

DioProfileRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioProfileRepository(apiClient: api);
}

void main() {
  group('DioProfileRepository', () {
    test('updateProfile mengirim PUT body partial (field kosong tidak ikut)',
        () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'PUT');
        expect(options.path, '/klien/profile');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {}});
      });

      await repo.updateProfile(
        usia: 26,
        jenisKelamin: 'wanita',
        tinggiBadanCm: 168,
        alergiMakanan: 'Laktosa',
      );

      expect(captured!['usia'], 26);
      expect(captured!['jenisKelamin'], 'wanita');
      expect(captured!['tinggiBadanCm'], 168);
      expect(captured!['alergiMakanan'], 'Laktosa');
      expect(captured!.containsKey('nama'), isFalse);
    });

    test('startNewCycle first-time menyertakan bbAwalKg', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/klien/progress-cycles');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {'message': 'ok'}});
      });

      await repo.startNewCycle(
        bbTujuanKg: 67,
        tujuan: 'turun_bb',
        durasiHari: 60,
        bbAwalKg: 78.5,
      );

      expect(captured!['bbTujuanKg'], 67);
      expect(captured!['tujuan'], 'turun_bb');
      expect(captured!['durasiHari'], 60);
      expect(captured!['bbAwalKg'], 78.5);
    });

    test('startNewCycle new-cycle tidak mengirim bbAwalKg', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': {'message': 'ok'}});
      });

      await repo.startNewCycle(bbTujuanKg: 70, tujuan: 'naik_bb', durasiHari: 30);

      expect(captured!.containsKey('bbAwalKg'), isFalse);
    });

    test('error 422 dipetakan ke pesan backend', () async {
      final repo = _repo((_) async => jsonResponse(
            {'error': 'Harap masukkan bbAwalKg untuk siklus pertama'},
            statusCode: 422,
          ));

      expect(
        () => repo.startNewCycle(
          bbTujuanKg: 67,
          tujuan: 'turun_bb',
          durasiHari: 60,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('bbAwalKg'),
          ),
        ),
      );
    });

    test('validasi 400 mengisi fieldErrors', () async {
      final repo = _repo(
        (_) async => jsonResponse({
          'error': {
            'fields': {
              'tinggiBadanCm': ['Harus angka positif']
            }
          }
        }, statusCode: 400),
      );

      try {
        await repo.updateProfile(tinggiBadanCm: -1);
        fail('Seharusnya melempar ApiException');
      } on ApiException catch (e) {
        expect(e.fieldErrors['tinggiBadanCm'], ['Harus angka positif']);
      }
    });

    test('error jaringan dipetakan ke pesan koneksi', () async {
      final repo = _repo((options) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'no network',
        );
      });

      expect(
        () => repo.updateProfile(usia: 20),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });
  });
}
