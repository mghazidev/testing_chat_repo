import '../data_sources/auth_remote_data_source.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _dataSource = AuthRemoteDataSource();

  Future<AuthResponseModel> login(String email, String password) =>
      _dataSource.login(email, password);

  Future<void> logout() => _dataSource.logout();

  Future<UserModel> verify() => _dataSource.verify();
}
