import 'package:dio/dio.dart';
import 'package:softex_chat_app/core/config/api_config.dart';

import '../constants/storage_keys.dart';
import 'api_exceptions.dart';
import 'package:get_storage/get_storage.dart';

class ApiClient {
  late final Dio _dio;
  final GetStorage _storage = GetStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.read<String>(StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        try {
          final uri = response.requestOptions.uri.toString();
          print('[API Response] $uri');
          print('[API Response] statusCode: ${response.statusCode}');
          print('[API Response] data: ${response.data}');
        } catch (_) {}
        return handler.next(response);
      },
      onError: (error, handler) {
        try {
          print('[API Error] ${error.requestOptions.uri}');
          print('[API Error] statusCode: ${error.response?.statusCode}');
          print('[API Error] response data: ${error.response?.data}');
          print('[API Error] message: ${error.message}');
        } catch (_) {}
        final apiException = ApiException(
          error.response?.data is Map
              ? (error.response!.data['message'] ?? error.message)
              : error.message,
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );
        return handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: apiException,
          response: error.response,
        ));
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);
}
