import 'package:get_storage/get_storage.dart';

import '../core/constants/storage_keys.dart';

class StorageService {
  static final GetStorage _box = GetStorage();

  static String? get accessToken => _box.read<String>(StorageKeys.accessToken);
  static set accessToken(String? value) {
    if (value == null) {
      _box.remove(StorageKeys.accessToken);
    } else {
      _box.write(StorageKeys.accessToken, value);
    }
  }

  static String? get userId => _box.read<String>(StorageKeys.userId);
  static set userId(String? value) {
    if (value == null) {
      _box.remove(StorageKeys.userId);
    } else {
      _box.write(StorageKeys.userId, value);
    }
  }

  static String? get userEmail => _box.read<String>(StorageKeys.userEmail);
  static set userEmail(String? value) {
    if (value == null) {
      _box.remove(StorageKeys.userEmail);
    } else {
      _box.write(StorageKeys.userEmail, value);
    }
  }

  static String? get userName => _box.read<String>(StorageKeys.userName);
  static set userName(String? value) {
    if (value == null) {
      _box.remove(StorageKeys.userName);
    } else {
      _box.write(StorageKeys.userName, value);
    }
  }

  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  static Future<void> clearAuth() async {
    _box.remove(StorageKeys.accessToken);
    _box.remove(StorageKeys.userId);
    _box.remove(StorageKeys.userEmail);
    _box.remove(StorageKeys.userName);
  }
}
