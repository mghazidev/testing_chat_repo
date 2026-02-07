import 'dart:io';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import 'storage_service.dart';

class FileUploadService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  FileUploadService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('[Upload Response] ${response.statusCode}');
        print('[Upload Data] ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('[Upload Error] ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  /// Upload a file to the server
  /// Returns the URL of the uploaded file
  Future<String> uploadFile(
    File file, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/v1/upload', // Adjust this endpoint based on your API
        data: formData,
        onSendProgress: onProgress,
      );

      // Adjust this based on your API response structure
      final url = response.data['data']['url'] as String;
      return url;
    } catch (e) {
      print('[FileUpload] Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload an image with optional compression
  Future<String> uploadImage(
    File imageFile, {
    Function(int, int)? onProgress,
  }) async {
    return uploadFile(imageFile, onProgress: onProgress);
  }

  /// Upload a document
  Future<String> uploadDocument(
    File documentFile, {
    Function(int, int)? onProgress,
  }) async {
    return uploadFile(documentFile, onProgress: onProgress);
  }

  /// Upload a video
  Future<String> uploadVideo(
    File videoFile, {
    Function(int, int)? onProgress,
  }) async {
    return uploadFile(videoFile, onProgress: onProgress);
  }
}
