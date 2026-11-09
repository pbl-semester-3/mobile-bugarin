import 'package:bugarin_mobile/features/auth/data/recovery_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_http.dart';
import 'fakes.dart';

DioRecoveryRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final api = ApiClient(tokenStorage: FakeTokenStorage(), onUnauthorized: () {});
  api.dio.httpClientAdapter = FakeHttpAdapter(handler);
  return DioRecoveryRepository(apiClient: api);
}

void main() {
  group('DioRecoveryRepository', () {
    test('forgotPassword kirim email', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/auth/forgot-password');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': 'ok'});
      });

      await repo.forgotPassword('budi@example.com');
      expect(captured!['email'], 'budi@example.com');
    });

    test('resetPassword kirim email, kode, passwordBaru', () async {
      Map<String, dynamic>? captured;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/auth/reset-password');
        captured = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse({'data': 'ok'});
      });

      await repo.resetPassword(
        email: 'budi@example.com',
        kode: '123456',
        passwordBaru: 'rahasia123',
      );

      expect(captured!['email'], 'budi@example.com');
      expect(captured!['kode'], '123456');
      expect(captured!['passwordBaru'], 'rahasia123');
    });

    test('error backend dipetakan ke ApiException', () async {
      final repo = _repo(
        (_) async => jsonResponse({'error': 'Kode verifikasi salah'}, statusCode: 400),
      );

      expect(
        () => repo.resetPassword(email: 'a@b.com', kode: '000000', passwordBaru: 'rahasia123'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Kode'))),
      );
    });
  });
}
