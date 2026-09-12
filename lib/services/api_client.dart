import 'package:dio/dio.dart';
import '../config/env.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final void Function() onUnauthorized;

  ApiClient({required this.tokenStorage, required this.onUnauthorized})
      : dio = Dio(BaseOptions(
          baseUrl: Env.apiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
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
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }
}

/// Error validasi dari backend, format: { "error": { "fields": { "email": ["..."] } } }
class ApiValidationError implements Exception {
  final Map<String, List<String>> fieldErrors;
  ApiValidationError(this.fieldErrors);

  factory ApiValidationError.fromDioException(DioException e) {
    final data = e.response?.data;
    final fields = (data is Map ? data['error'] : null);
    if (fields is Map && fields['fields'] is Map) {
      final map = (fields['fields'] as Map).map(
        (k, v) => MapEntry(k.toString(), List<String>.from(v as List)),
      );
      return ApiValidationError(map);
    }
    return ApiValidationError({});
  }
}

extension DioResponseX on Response {
  T unwrap<T>(T Function(dynamic json) fromJson) => fromJson(data['data']);
}
