import 'package:get/get.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/storage_service.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepo = UserRepository();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    error.value = '';
    try {
      user.value = await _userRepo.getCurrentUser();
      print('[Profile] getCurrentUser success: userId=${user.value?.id}, name=${user.value?.name}');
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

  Future<void> updateProfile({String? name, String? bio, String? phone}) async {
    saving.value = true;
    error.value = '';
    try {
      user.value = await _userRepo.updateProfile(name: name, bio: bio, phone: phone);
      print('[Profile] updateProfile success: userId=${user.value?.id}');
      if (name != null) StorageService.userName = name;
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      saving.value = false;
    }
  }
}
