import 'package:get/get.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/storage_service.dart';
import '../../core/routes/app_routes.dart';
import '../chat_list/chat_list_controller.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  bool get isLoggedIn => StorageService.isLoggedIn;
  String? get userId => StorageService.userId;
  String? get userName => StorageService.userName;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _authRepo.login(email, password);
      print(
          '[Auth] Login success: userId=${res.user.id}, name=${res.user.name}, token length=${res.token.length}');
      _saveAuth(res);
      try {
        await _userRepo.updateOnlineStatus(true);
      } catch (_) {}
      Get.offAllNamed(AppRoutes.chatList);
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _saveAuth(AuthResponseModel res) {
    StorageService.accessToken = res.token;
    StorageService.userId = res.user.id;
    StorageService.userName = res.user.name ?? res.user.email ?? '';
    StorageService.userEmail = res.user.email;
  }

  Future<bool> verifyAndGo() async {
    if (!StorageService.isLoggedIn) return false;
    isLoading.value = true;
    try {
      final user = await _authRepo.verify();
      StorageService.userId = user.id;
      StorageService.userName = user.name ?? user.email ?? '';
      StorageService.userEmail = user.email;

      print('[Auth] Verify success: userId=${user.id}, name=${user.name}');
      try {
        await _userRepo.updateOnlineStatus(true);
      } catch (_) {}
      return true;
    } catch (e) {
      print('[Auth] Verify failed: $e');
      showApiError(e);
      await StorageService.clearAuth();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      try {
        await _userRepo.updateOnlineStatus(false);
      } catch (_) {}
      await _authRepo.logout();
      print('[Auth] Logout success');
    } catch (e) {
      showApiError(e);
    }
    await StorageService.clearAuth();
    Get.delete<ChatListController>(force: true);
    isLoading.value = false;
    Get.offAllNamed(AppRoutes.login);
  }
}
