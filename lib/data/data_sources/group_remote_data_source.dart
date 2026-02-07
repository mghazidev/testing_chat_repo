import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../models/group_model.dart';

class GroupRemoteDataSource {
  final ApiClient _client = ApiClient();

  Future<GroupModel> getGroup(String groupId) async {
    try {
      final res = await _client.get(ApiEndpoints.group(groupId));
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return GroupModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get group failed');
    }
  }

  Future<GroupModel> updateGroup(String groupId, {String? name, String? description, String? avatar}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (avatar != null) body['avatar'] = avatar;
      final res = await _client.put(ApiEndpoints.group(groupId), data: body);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return GroupModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Update group failed');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _client.delete(ApiEndpoints.group(groupId));
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Delete group failed');
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _client.post(ApiEndpoints.groupLeave(groupId));
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Leave group failed');
    }
  }

  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    try {
      final res = await _client.get(ApiEndpoints.groupMembers(groupId));
      final data = unwrapResponse(res.data);
      if (data is List) {
        return data.map((e) => GroupMemberModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (data is Map && data['members'] is List) {
        return (data['members'] as List)
            .map((e) => GroupMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get members failed');
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    try {
      await _client.post(ApiEndpoints.groupMembers(groupId), data: {'userId': userId});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Add member failed');
    }
  }

  Future<void> updateMemberRole(String groupId, String memberId, String role) async {
    try {
      await _client.put(ApiEndpoints.groupMember(groupId, memberId), data: {'role': role});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Update role failed');
    }
  }

  Future<void> removeMember(String groupId, String memberId) async {
    try {
      await _client.delete(ApiEndpoints.groupMember(groupId, memberId));
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Remove member failed');
    }
  }

  Future<GroupSettingsModel> getSettings(String groupId) async {
    try {
      final res = await _client.get(ApiEndpoints.groupSettings(groupId));
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return GroupSettingsModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get settings failed');
    }
  }

  Future<GroupSettingsModel> updateSettings(String groupId, Map<String, dynamic> settings) async {
    try {
      final res = await _client.put(ApiEndpoints.groupSettings(groupId), data: settings);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return GroupSettingsModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Update settings failed');
    }
  }
}
