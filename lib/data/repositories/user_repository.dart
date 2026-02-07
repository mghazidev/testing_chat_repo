import '../data_sources/user_remote_data_source.dart';
import '../models/user_model.dart';

class UserRepository {
  final UserRemoteDataSource _dataSource = UserRemoteDataSource();

  Future<UserModel> getCurrentUser() => _dataSource.getCurrentUser();

  Future<UserModel> getUser(String userId) => _dataSource.getUser(userId);

  Future<List<UserModel>> searchUsers(String query) => _dataSource.searchUsers(query);

  Future<UserModel> updateProfile({
    String? name,
    String? avatar,
    String? phone,
    String? bio,
    String? status,
  }) =>
      _dataSource.updateProfile(name: name, avatar: avatar, phone: phone, bio: bio, status: status);

  Future<void> updateOnlineStatus(bool isOnline) => _dataSource.updateOnlineStatus(isOnline);
}
