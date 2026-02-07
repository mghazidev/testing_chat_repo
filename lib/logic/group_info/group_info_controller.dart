import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';

class GroupInfoController extends GetxController {
  final GroupRepository _groupRepo = GroupRepository();
  final UserRepository _userRepo = UserRepository();
  final SocketService _socket = Get.find<SocketService>();

  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool actionLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxBool searching = false.obs;

  String _groupId = '';
  String _chatId = '';
  String get currentUserId => StorageService.userId ?? '';

  bool get isCurrentUserAdmin {
    final g = group.value;
    if (g == null) return false;
    final member =
        g.members?.firstWhereOrNull((m) => m.userId == currentUserId);
    return member?.role.toLowerCase() == 'admin';
  }

  final Rx<GroupSettingsModel?> settings = Rx<GroupSettingsModel?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _groupId = args['groupId'] as String? ?? '';
      _chatId = args['chatId'] as String? ?? '';
      if (_groupId.isNotEmpty) {
        _loadGroup(_groupId);
        loadSettings();
      }
    }
  }

  Future<void> _loadGroup(String id) async {
    isLoading.value = true;
    error.value = '';
    try {
      group.value = await _groupRepo.getGroup(id);
      print(
          '[GroupInfo] getGroup success: groupId=$id, name=${group.value?.name}, members=${group.value?.members?.length}');

      if (group.value?.settings != null) {
        settings.value = GroupSettingsModel.fromJson(group.value!.settings!);
      }
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

  Future<void> loadSettings() async {
    if (_groupId.isEmpty) return;
    try {
      settings.value = await _groupRepo.getSettings(_groupId);
      print(
          '[GroupInfo] getSettings success: groupId=$_groupId, onlyAdminsCanSend=${settings.value?.onlyAdminsCanSend}');
    } catch (e) {
      print('[GroupInfo] loadSettings error: $e');
      showApiError(e);
    }
  }

  Future<void> updateGroup({
    String? name,
    String? description,
    String? avatar,
  }) async {
    if (_groupId.isEmpty) return;

    actionLoading.value = true;
    try {
      if ((name == null || name.isEmpty) &&
          (description == null || description.isEmpty) &&
          (avatar == null || avatar.isEmpty)) {
        print('[GroupInfo] updateGroup: No changes to update');
        actionLoading.value = false;
        return;
      }

      await _groupRepo.updateGroup(
        _groupId,
        name: name?.isNotEmpty == true ? name : null,
        description: description?.isNotEmpty == true ? description : null,
        avatar: avatar?.isNotEmpty == true ? avatar : null,
      );

      print(
          '[GroupInfo] updateGroup success: groupId=$_groupId, name=$name, description=$description');

      await _loadGroup(_groupId);

      Get.snackbar('Success', 'Group updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> addMember(String userId) async {
    if (_groupId.isEmpty || userId.isEmpty) return;

    final existingMember =
        group.value?.members?.firstWhereOrNull((m) => m.userId == userId);
    if (existingMember != null) {
      Get.snackbar('Info', 'User is already a member of this group',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    actionLoading.value = true;
    try {
      await _groupRepo.addMember(_groupId, userId);
      print('[GroupInfo] addMember success: groupId=$_groupId, userId=$userId');

      await _loadGroup(_groupId);

      Get.snackbar('Success', 'Member added successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> updateMemberRole(String userId, String role) async {
    if (_groupId.isEmpty || userId.isEmpty) return;

    actionLoading.value = true;
    try {
      await _groupRepo.updateMemberRole(_groupId, userId, role);
      print(
          '[GroupInfo] updateMemberRole success: groupId=$_groupId, userId=$userId, role=$role');

      await _loadGroup(_groupId);

      Get.snackbar('Success', 'Member role updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> removeMember(String userId) async {
    if (_groupId.isEmpty || userId.isEmpty) return;

    actionLoading.value = true;
    try {
      await _groupRepo.removeMember(_groupId, userId);
      print(
          '[GroupInfo] removeMember success: groupId=$_groupId, userId=$userId');

      await _loadGroup(_groupId);

      Get.snackbar('Success', 'Member removed successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    if (_groupId.isEmpty) return;

    actionLoading.value = true;
    try {
      await _groupRepo.updateSettings(_groupId, updates);
      print(
          '[GroupInfo] updateSettings success: groupId=$_groupId, updates=$updates');

      await loadSettings();

      Get.snackbar('Success', 'Settings updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    searching.value = true;
    try {
      final results = await _userRepo.searchUsers(query.trim());

      final memberIds =
          group.value?.members?.map((m) => m.userId).toList() ?? [];
      searchResults.value =
          results.where((u) => !memberIds.contains(u.id)).toList();

      print(
          '[GroupInfo] searchUsers success: query=$query, count=${searchResults.length}');
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      searching.value = false;
    }
  }

  void clearSearch() {
    searchResults.clear();
  }

  Future<void> deleteGroup() async {
    if (_groupId.isEmpty) return;

    actionLoading.value = true;
    try {
      await _groupRepo.deleteGroup(_groupId);
      print('[GroupInfo] deleteGroup success: groupId=$_groupId');

      Get.back();
      Get.back();

      Get.snackbar('Success', 'Group deleted successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> leaveGroup() async {
    if (_groupId.isEmpty) return;

    actionLoading.value = true;
    try {
      await _groupRepo.leaveGroup(_groupId);
      print('[GroupInfo] leaveGroup success: groupId=$_groupId');

      Get.back();
      Get.back();

      Get.snackbar('Success', 'Left group successfully',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      showApiError(e);
    } catch (e) {
      showApiError(e);
    } finally {
      actionLoading.value = false;
    }
  }
}




// import 'package:get/get.dart';

// import '../../core/network/api_exceptions.dart';
// import '../../core/utils/error_display.dart';
// import '../../data/models/group_model.dart';
// import '../../data/models/user_model.dart';
// import '../../data/repositories/group_repository.dart';
// import '../../data/repositories/user_repository.dart';
// import '../../core/routes/app_routes.dart';
// import '../../services/storage_service.dart';

// class GroupInfoController extends GetxController {
//   final GroupRepository _groupRepo = GroupRepository();
//   final UserRepository _userRepo = UserRepository();

//   final Rx<GroupModel?> group = Rx<GroupModel?>(null);
//   final Rx<GroupSettingsModel?> settings = Rx<GroupSettingsModel?>(null);
//   final RxBool isLoading = true.obs;
//   final RxBool actionLoading = false.obs;
//   final RxString error = ''.obs;
  
//   // User search for adding members
//   final RxList<UserModel> searchResults = <UserModel>[].obs;
//   final RxBool searching = false.obs;
//   String _searchQuery = '';

//   String? get groupId => Get.arguments?['groupId'] as String?;
//   String? get chatId => Get.arguments?['chatId'] as String?;
//   String? get currentUserId => StorageService.userId;

//   /// Whether the current user has admin privileges in this group.
//   /// A user is considered admin if:
//   /// - they are the group creator (`createdBy`), or
//   /// - they appear in members list with role == 'admin'.
//   bool get isCurrentUserAdmin {
//     final g = group.value;
//     final uid = currentUserId;
//     if (g == null || uid == null || uid.isEmpty) return false;

//     final isCreator = g.createdBy == uid;
//     final isAdminMember = (g.members ?? [])
//         .any((m) => m.userId == uid && m.role.toLowerCase() == 'admin');
//     return isCreator || isAdminMember;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     if (groupId != null) {
//       loadGroup();
//       loadSettings();
//     }
//   }

//   Future<void> loadGroup() async {
//     if (groupId == null) return;
//     isLoading.value = true;
//     error.value = '';
//     try {
//       group.value = await _groupRepo.getGroup(groupId!);
//       print('[GroupInfo] getGroup success: groupId=$groupId, name=${group.value?.name}, members=${group.value?.members?.length}');
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> loadSettings() async {
//     if (groupId == null) return;
//     try {
//       settings.value = await _groupRepo.getSettings(groupId!);
//       print('[GroupInfo] getSettings success: groupId=$groupId, onlyAdminsCanSend=${settings.value?.onlyAdminsCanSend}');
//     } on ApiException catch (e) {
//       showApiError(e);
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> updateGroup({String? name, String? description, String? avatar}) async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       group.value = await _groupRepo.updateGroup(
//         groupId!,
//         name: name,
//         description: description,
//         avatar: avatar,
//       );
//       print('[GroupInfo] updateGroup success: groupId=$groupId');
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> updateSettings(Map<String, dynamic> newSettings) async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       final updated = await _groupRepo.updateSettings(groupId!, newSettings);
//       settings.value = updated;
//       print('[GroupInfo] updateSettings success: groupId=$groupId');
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> leaveGroup() async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       await _groupRepo.leaveGroup(groupId!);
//       print('[GroupInfo] leaveGroup success: groupId=$groupId');
//       Get.until((route) => route.settings.name == AppRoutes.chatList);
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> addMember(String userId) async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       await _groupRepo.addMember(groupId!, userId);
//       print('[GroupInfo] addMember success: groupId=$groupId, userId=$userId');
//       await loadGroup();
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> removeMember(String memberId) async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       await _groupRepo.removeMember(groupId!, memberId);
//       print('[GroupInfo] removeMember success: groupId=$groupId, memberId=$memberId');
//       await loadGroup();
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> updateMemberRole(String memberId, String role) async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       await _groupRepo.updateMemberRole(groupId!, memberId, role);
//       print(
//           '[GroupInfo] updateMemberRole success: groupId=$groupId, memberId=$memberId, role=$role');
//       await loadGroup();
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> deleteGroup() async {
//     if (groupId == null) return;
//     actionLoading.value = true;
//     error.value = '';
//     try {
//       await _groupRepo.deleteGroup(groupId!);
//       print('[GroupInfo] deleteGroup success: groupId=$groupId');
//       // After deleting the group, return user back to chat list.
//       Get.until((route) => route.settings.name == AppRoutes.chatList);
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       actionLoading.value = false;
//     }
//   }

//   Future<void> searchUsers(String query) async {
//     _searchQuery = query.trim();
//     if (_searchQuery.isEmpty) {
//       searchResults.clear();
//       return;
//     }
//     searching.value = true;
//     try {
//       final list = await _userRepo.searchUsers(_searchQuery);
//       // Filter out users who are already members
//       final currentMemberIds = (group.value?.members ?? []).map((m) => m.userId).toSet();
//       final filtered = list.where((u) => !currentMemberIds.contains(u.id)).toList();
//       searchResults.assignAll(filtered);
//       print('[GroupInfo] searchUsers success: query=$_searchQuery, count=${filtered.length}');
//     } on ApiException catch (e) {
//       searchResults.clear();
//       showApiError(e);
//     } catch (e) {
//       searchResults.clear();
//       print('[GroupInfo] searchUsers error: $e');
//     } finally {
//       searching.value = false;
//     }
//   }

//   void clearSearch() {
//     _searchQuery = '';
//     searchResults.clear();
//   }
// }
