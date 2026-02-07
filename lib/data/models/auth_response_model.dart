import 'user_model.dart';

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({required this.token, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // API returns { success: true, data: { user: {...}, token: "..." } }
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final token = (data['token'] ??
            data['accessToken'] ??
            json['token'] ??
            json['accessToken'] ??
            '')
        .toString();
    final user = UserModel.fromJson(userJson);
    return AuthResponseModel(token: token, user: user);
  }
}
