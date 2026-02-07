import 'package:get/get.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/socket_service.dart';
import '../../core/routes/app_routes.dart';

class NewChatController extends GetxController {
  final UserRepository _userRepo = UserRepository();
  final ChatRepository _chatRepo = ChatRepository();
  final SocketService _socket = Get.find<SocketService>();

  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxList<String> selectedMemberIds = <String>[].obs;
  final RxBool searching = false.obs;
  final RxBool creating = false.obs;
  final RxString error = ''.obs;

  String _query = '';
  String get query => _query;

  void toggleMember(String userId) {
    if (selectedMemberIds.contains(userId)) {
      selectedMemberIds.remove(userId);
    } else {
      selectedMemberIds.add(userId);
    }
  }

  bool isSelected(String userId) => selectedMemberIds.contains(userId);

  void clearSelection() => selectedMemberIds.clear();

  Future<void> search(String q) async {
    _query = q.trim();
    if (_query.isEmpty) {
      searchResults.clear();
      return;
    }
    searching.value = true;
    error.value = '';
    try {
      final list = await _userRepo.searchUsers(_query);
      print('[NewChat] searchUsers success: query=$_query, count=${list.length}');
      searchResults.assignAll(list);
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      searching.value = false;
    }
  }

  Future<void> createDirectChat(String userId) async {
    creating.value = true;
    error.value = '';
    try {
      final created = await _chatRepo.createDirectChat(userId);
      print('[NewChat] createDirectChat success: chatId=${created.id}, name=${created.name}');
      final participantIds = created.participantIds ?? [userId];
      _socket.notifyNewChatCreated(created.id, {'id': created.id, 'name': created.name}, participantIds);
      Get.offNamed(AppRoutes.chatRoom, arguments: {'chatId': created.id, 'chat': created});
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      creating.value = false;
    }
  }

  Future<void> createGroup(String name, String? description, [List<String>? participantIds]) async {
    final ids = participantIds ?? selectedMemberIds.toList();
    if (name.trim().isEmpty || ids.isEmpty) {
      error.value = 'Name and at least one participant required';
      return;
    }
    creating.value = true;
    error.value = '';
    try {
      final created = await _chatRepo.createGroup(
        name: name.trim(),
        description: description?.trim(),
        participantIds: ids,
      );
      print('[NewChat] createGroup success: chatId=${created.id}, name=${created.name}, participants=${created.participantIds?.length}');
      final createdIds = created.participantIds ?? ids;
      _socket.notifyNewChatCreated(created.id, {'id': created.id, 'name': created.name}, createdIds);
      Get.offNamed(AppRoutes.chatRoom, arguments: {'chatId': created.id, 'chat': created});
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      creating.value = false;
    }
  }

  void clearSearch() {
    _query = '';
    searchResults.clear();
    error.value = '';
  }
}
