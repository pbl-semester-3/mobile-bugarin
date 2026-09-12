---
name: dio-jwt-networking
description: Setup Dio HTTP client dengan interceptor JWT (flutter_secure_storage) untuk Mobile Klien Bugarin, selaras dengan strategi bearer-token yang dipakai backend. Gunakan saat setup networking layer atau menambah endpoint baru.
metadata:
  origin: bugarin-project
  adapted_from: ECC dart-flutter-patterns (MIT license, https://github.com/affaan-m/ECC)
---

# Dio + JWT Networking (Bugarin Mobile)

Mobile Klien pakai strategi token **berbeda** dari Web (lihat skill `jwt-auth-security` di sisi backend): token dikembalikan di response body saat login, disimpan di `flutter_secure_storage`, dan dikirim manual lewat header `Authorization: Bearer` — bukan cookie.

## Activation

- Setup networking layer awal project.
- Menambah endpoint baru yang butuh dipanggil dari Mobile.
- Debug error 401 yang tidak seharusnya terjadi (token hilang/expired).

## Setup

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.0
```

## Token Storage Service

```dart
// services/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage(); // pakai Keychain (iOS) / Keystore (Android)

  Future<void> save(String token) => _storage.write(key: 'auth_token', value: token);
  Future<String?> read() => _storage.read(key: 'auth_token');
  Future<void> clear() => _storage.delete(key: 'auth_token');
}
```

**Jangan** pakai `shared_preferences` untuk token — itu penyimpanan plaintext biasa, bukan secure enclave. `flutter_secure_storage` wajib untuk data auth.

## Dio Client + Interceptor

```dart
// services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final void Function() onUnauthorized; // dipanggil untuk redirect ke login

  ApiClient({required this.tokenStorage, required this.onUnauthorized})
      : dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment('API_URL'),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStorage.clear();
          onUnauthorized(); // GoRouter redirect ke /login, lihat gorouter-navigation-bugarin
        }
        handler.next(error);
      },
    ));
  }
}
```

Bugarin **tidak** mengimplementasikan refresh token di MVP ini (token JWT expired 7 hari, cukup arahkan login ulang saat 401 — lihat `jwt-auth-security` bab Penerbitan Token). Jangan bangun logic refresh-token yang tidak ada endpoint-nya di backend.

## Registrasi ke Riverpod

```dart
// providers/api_client_provider.dart
@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(routerProvider).go('/login'),
  );
}
```

## Response Envelope (samakan dengan `api-contract-bugarin`)

Backend selalu bungkus `{ "data": ... }` atau `{ "error": ... }` (lihat skill `api-contract-bugarin`). Buat helper supaya tidak berulang `response.data['data']` di tiap pemanggilan:

```dart
extension DioResponseX on Response {
  T unwrap<T>(T Function(dynamic json) fromJson) => fromJson(data['data']);
}

// Pemakaian:
final response = await dio.get('/klien/profile');
final profile = response.unwrap((json) => KlienProfile.fromJson(json));
```

## Error Handling per Field (mengikuti format Zod backend)

```dart
class ApiValidationError implements Exception {
  final Map<String, List<String>> fieldErrors;
  ApiValidationError(this.fieldErrors);

  factory ApiValidationError.fromDioError(DioException e) {
    final fields = e.response?.data?['error']?['fields'] as Map<String, dynamic>?;
    return ApiValidationError(
      fields?.map((k, v) => MapEntry(k, List<String>.from(v))) ?? {},
    );
  }
}
```

Tangkap ini di layer form (lihat skill `flutter-form-validation`) untuk tampilkan pesan error per field, konsisten dengan pola yang sama di Web (`form-validation-patterns`).

## Anti-Patterns

| Anti-Pattern | Risiko | Perbaikan |
|---|---|---|
| Simpan token di `shared_preferences` | Bukan secure storage, mudah diakses lewat root/jailbreak device | `flutter_secure_storage` |
| Bangun logic refresh-token tanpa endpoint di backend | Kompleksitas tanpa fungsi, bug tak terduga | Cukup redirect login ulang saat 401 (sesuai scope MVP) |
| Hardcode `baseUrl` langsung di kode | Sulit beda environment dev/staging/prod | `String.fromEnvironment` + `--dart-define` saat build |
| Parsing response manual berulang tiap pemanggilan API | Duplikasi kode, gampang salah key | Extension `unwrap()` terpusat |

## Related

- Skill: `flutter-riverpod-patterns` — `apiClientProvider` dipakai di semua provider data
- Skill: `gorouter-navigation-bugarin` — redirect ke `/login` saat `onUnauthorized` terpanggil
- Skill: `api-contract-bugarin` (backend) — bentuk response yang di-`unwrap()` di atas
