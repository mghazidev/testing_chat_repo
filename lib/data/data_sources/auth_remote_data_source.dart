import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client = ApiClient();

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final res = await _client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response');
      }
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Logout failed');
    }
  }

  Future<UserModel> verify() async {
    try {
      final res = await _client.get(ApiEndpoints.verify);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Verify failed');
    }
  }
}
