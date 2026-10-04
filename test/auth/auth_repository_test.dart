import 'dart:convert';
import 'dart:typed_data';

import 'package:bugarin_mobile/features/auth/data/auth_repository.dart';
import 'package:bugarin_mobile/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Adapter Dio palsu — mengembalikan response JSON buatan tanpa network.
class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

DioAuthRepository _repoWith(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  FakeTokenStorage? storage,
}) {
  final tokenStorage = storage ?? FakeTokenStorage();
  final api = ApiClient(tokenStorage: tokenStorage, onUnauthorized: () {});
  api.dio.httpClientAdapter = _FakeAdapter(handler);
  return DioAuthRepository(apiClient: api, tokenStorage: tokenStorage);
}

void main() {
  group('DioAuthRepository', () {
    test('login sukses menyimpan token & mengembalikan role', () async {
      final storage = FakeTokenStorage();
      final repo = _repoWith((options) async {
        expect(options.path, '/auth/login');
        expect(options.headers['X-Client-Type'], 'mobile');
        return _json({
          'data': {'token': 'jwt-abc', 'role': 'klien'}
        });
      }, storage: storage);

      final result = await repo.login(emailOrUsername: 'budi', password: 'secret12');

      expect(result.token, 'jwt-abc');
      expect(result.role, 'klien');
      expect(storage.savedToken, 'jwt-abc');
    });

    test('login gagal 401 memetakan pesan error backend', () async {
      final repo = _repoWith(
        (_) async => _json(
          {'error': 'Email/username atau password salah'},
          statusCode: 401,
        ),
      );

      expect(
        () => repo.login(emailOrUsername: 'x', password: 'y'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email/username atau password salah',
          ),
        ),
      );
    });

    test('register validasi 400 mengisi fieldErrors', () async {
      final repo = _repoWith(
        (_) async => _json({
          'error': {
            'fields': {
              'email': ['Format email tidak valid']
            }
          }
        }, statusCode: 400),
      );

      try {
        await repo.register(
          nama: 'A',
          email: 'bad',
          username: 'abc',
          password: '12345678',
        );
        fail('Seharusnya melempar AuthException');
      } on AuthException catch (e) {
        expect(e.fieldErrors['email'], ['Format email tidak valid']);
        expect(e.message, 'Format email tidak valid');
      }
    });

    test('getProfile mem-parse profileComplete & activeCycle', () async {
      final repo = _repoWith((options) async {
        expect(options.path, '/klien/profile');
        return _json({
          'data': {
            'id': 1,
            'userId': 10,
            'nama': 'Maya',
            'usia': 26,
            'jenisKelamin': 'wanita',
            'tinggiBadanCm': 168,
            'ptId': null,
            'user': {
              'email': 'maya@example.com',
              'username': 'mayaa',
              'tema': 'malam',
            },
            'profileComplete': true,
            'activeCycle': {
              'id': 5,
              'klienId': 1,
              'bbAwalKg': 78.5,
              'bbTujuanKg': 67.0,
              'tujuan': 'turun_bb',
              'durasiHari': 60,
              'targetKaloriPerHari': 1980,
              'streak': 12,
              'status': 'aktif',
              'tanggalMulai': '2026-09-01',
              'tanggalSelesai': null,
            },
          }
        });
      });

      final profile = await repo.getProfile();

      expect(profile.nama, 'Maya');
      expect(profile.email, 'maya@example.com');
      expect(profile.profileComplete, isTrue);
      expect(profile.hasPt, isFalse);
      expect(profile.activeCycle?.targetKaloriPerHari, 1980);
      expect(profile.activeCycle?.isActive, isTrue);
    });

    test('getProfile tanpa cycle aktif tetap valid', () async {
      // Backend meng-Omit key `activeCycle` saat kosong (bukan null eksplisit).
      final repo = _repoWith((_) async => _json({
            'data': {
              'id': 1,
              'userId': 10,
              'nama': 'Baru',
              'user': {'email': 'baru@example.com', 'username': 'baru'},
              'profileComplete': false,
            }
          }));

      final profile = await repo.getProfile();

      expect(profile.profileComplete, isFalse);
      expect(profile.activeCycle, isNull);
    });

    test('mem-parse payload asli GET /klien/profile (fixture verifikasi manual)',
        () async {
      final repo = _repoWith((_) async => _json({
            'data': {
              'id': 600000127,
              'userId': 132,
              'nama': 'Auth Test',
              'usia': 26,
              'jenisKelamin': 'wanita',
              'alergiMakanan': 'Laktosa',
              'tinggiBadanCm': 168,
              'ptId': null,
              'user': {
                'id': 132,
                'email': 'auth.test@example.com',
                'username': 'authtest',
                'role': 'klien',
                'tema': 'siang',
                'createdAt': '2026-10-03T11:03:57.000Z',
                'updatedAt': '2026-10-03T11:03:57.000Z',
              },
              'profileComplete': true,
              'activeCycle': {
                'id': 63,
                'klienId': 600000127,
                'bbAwalKg': 78.5,
                'bbTujuanKg': 67,
                'tujuan': 'turun_bb',
                'durasiHari': 60,
                'targetKaloriPerHari': 1662,
                'streak': 0,
                'status': 'aktif',
                'tanggalMulai': '2026-10-03',
                'tanggalSelesai': null,
              },
            }
          }));

      final profile = await repo.getProfile();

      expect(profile.id, 600000127);
      expect(profile.userId, 132);
      expect(profile.jenisKelamin, 'wanita');
      expect(profile.tinggiBadanCm, 168);
      expect(profile.alergiMakanan, 'Laktosa');
      expect(profile.profileComplete, isTrue);
      expect(profile.activeCycle?.id, 63);
      expect(profile.activeCycle?.targetKaloriPerHari, 1662);
      expect(profile.activeCycle?.bbAwalKg, 78.5);
      expect(profile.activeCycle?.status, 'aktif');
      expect(profile.activeCycle?.isActive, isTrue);
    });

    test('error jaringan dipetakan ke pesan koneksi', () async {
      final repo = _repoWith((options) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'no network',
        );
      });

      expect(
        () => repo.login(emailOrUsername: 'x', password: 'y'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });

    test('logout tetap clear token walau backend error', () async {
      final storage = FakeTokenStorage()..seed('jwt-abc');
      final repo = _repoWith(
        (_) async => _json({'error': 'Internal server error'}, statusCode: 500),
        storage: storage,
      );

      await repo.logout();

      expect(storage.cleared, isTrue);
      expect(storage.savedToken, isNull);
    });
  });
}
