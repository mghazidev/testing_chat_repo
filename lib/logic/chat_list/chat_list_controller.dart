import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';
import '../../core/routes/app_routes.dart';

class ChatListController extends GetxController {
  final ChatRepository _chatRepo = ChatRepository();
  final SocketService _socket = Get.find<SocketService>();

  final RxList<ChatModel> chats = <ChatModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  StreamSubscription? _messageSub;
  StreamSubscription? _chatCreatedSub;

  @override
  void onInit() {
    super.onInit();
    _messageSub = _socket.onReceiveMessage.listen((msg) {
      refreshChatList();
    });
    _chatCreatedSub = _socket.onChatCreated.listen((_) {
      refreshChatList();
    });
    loadChats();
    _connectSocket();
  }

  void _connectSocket() {
    final ids = chats.map((c) => c.id).toList();
    if (ids.isNotEmpty) {
      _socket.connectGlobal(ids);
    }
  }

  Future<void> loadChats() async {
    isLoading.value = true;
    error.value = '';
    try {
      final list = await _chatRepo.getAllChats();
      print('[ChatList] getAllChats success: ${list.length} chats');
      chats.assignAll(list);
      if (_socket.isConnected == false && list.isNotEmpty) {
        _socket.connectGlobal(list.map((c) => c.id).toList());
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

  Future<void> refreshChatList() async {
    try {
      final list = await _chatRepo.getAllChats();
      print('[ChatList] refreshChatList success: ${list.length} chats');
      chats.assignAll(list);
    } catch (e) {
      showApiError(e);
    }
  }

  void openChat(ChatModel chat) {
    Get.toNamed(AppRoutes.chatRoom,
        arguments: {'chatId': chat.id, 'chat': chat});
  }

  void openNewChat() {
    Get.toNamed(AppRoutes.newChat);
  }

  void openProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  @override
  void onClose() {
    _messageSub?.cancel();
    _chatCreatedSub?.cancel();
    super.onClose();
  }
}
