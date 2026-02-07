import '../data_sources/group_remote_data_source.dart';
import '../models/group_model.dart';

class GroupRepository {
  final GroupRemoteDataSource _dataSource = GroupRemoteDataSource();

  Future<GroupModel> getGroup(String groupId) => _dataSource.getGroup(groupId);

  Future<GroupModel> updateGroup(String groupId, {String? name, String? description, String? avatar}) =>
      _dataSource.updateGroup(groupId, name: name, description: description, avatar: avatar);

  Future<void> deleteGroup(String groupId) => _dataSource.deleteGroup(groupId);

  Future<void> leaveGroup(String groupId) => _dataSource.leaveGroup(groupId);

  Future<List<GroupMemberModel>> getMembers(String groupId) => _dataSource.getMembers(groupId);

  Future<void> addMember(String groupId, String userId) => _dataSource.addMember(groupId, userId);

  Future<void> updateMemberRole(String groupId, String memberId, String role) =>
      _dataSource.updateMemberRole(groupId, memberId, role);

  Future<void> removeMember(String groupId, String memberId) =>
      _dataSource.removeMember(groupId, memberId);

  Future<GroupSettingsModel> getSettings(String groupId) => _dataSource.getSettings(groupId);

  Future<GroupSettingsModel> updateSettings(String groupId, Map<String, dynamic> settings) =>
      _dataSource.updateSettings(groupId, settings);
}
