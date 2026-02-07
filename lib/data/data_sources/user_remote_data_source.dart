import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  final ApiClient _client = ApiClient();

  Future<UserModel> getCurrentUser() async {
    try {
      final res = await _client.get(ApiEndpoints.currentUser);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get profile failed');
    }
  }

  Future<UserModel> getUser(String userId) async {
    try {
      final res = await _client.get(ApiEndpoints.user(userId));
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get user failed');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final res = await _client.get(ApiEndpoints.userSearch, queryParameters: {'q': query});
      final data = unwrapResponse(res.data);
      if (data is List) {
        return data.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (data is Map && data['users'] is List) {
        return (data['users'] as List)
            .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Search failed');
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? avatar,
    String? phone,
    String? bio,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (avatar != null) body['avatar'] = avatar;
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (status != null) body['status'] = status;
      final res = await _client.put(ApiEndpoints.currentUser, data: body);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Update profile failed');
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await _client.put(ApiEndpoints.userStatus, data: {'isOnline': isOnline});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Update status failed');
    }
  }
}
