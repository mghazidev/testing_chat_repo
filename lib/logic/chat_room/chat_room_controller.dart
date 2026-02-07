import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/error_display.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/pinned_message_model.dart';
import '../../data/models/reaction_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/message_reactions_repository.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';
import '../chat_list/chat_list_controller.dart';

class ChatRoomController extends GetxController {
  final ChatRepository _chatRepo = ChatRepository();
  final MessageReactionsRepository _reactionsRepo =
      MessageReactionsRepository();
  final SocketService _socket = Get.find<SocketService>();

  final Rx<ChatModel?> chat = Rx<ChatModel?>(null);
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool sending = false.obs;
  final RxString error = ''.obs;
  final Rx<PinnedMessageModel?> pinnedMessage = Rx<PinnedMessageModel?>(null);
  final RxString typingUser = ''.obs;

  // FIXED: Use RxMap properly for reactive updates
  final RxMap<String, List<ReactionModel>> reactionsByMessage =
      <String, List<ReactionModel>>{}.obs;

  String get chatId => chat.value?.id ?? _chatIdArg;
  String _chatIdArg = '';
  String get currentUserId => StorageService.userId ?? '';
  String get currentUserName => StorageService.userName ?? '';

  StreamSubscription? _receiveSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _stopTypingSub;
  StreamSubscription? _editedSub;
  StreamSubscription? _deletedSub;
  StreamSubscription? _pinnedSub;
  StreamSubscription? _unpinnedSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _reactionAddedSub;
  StreamSubscription? _reactionRemovedSub;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      chat.value = args['chat'] as ChatModel?;
      final id = args['chatId'] as String? ?? chat.value?.id ?? '';
      _chatIdArg = id;
      if (id.isNotEmpty) {
        _loadChat(id);
        _loadMessages(id);
        _loadPinned(id);
        _socket.joinChat(id);
        _socket.subscribeChatRoom(id);
        _subscribeSocket(id);
      }
    }
  }

  void _subscribeSocket(String cid) {
    print('[ChatRoom] Subscribing to socket events for chat: $cid');

    _receiveSub = _socket.onReceiveMessage.listen((msg) {
      if (msg.chatId == cid) {
        print(
            '[ChatRoom] ✅ Received message via socket: ${msg.id}, content: ${msg.content}');
        final exists = messages.indexWhere((m) => m.id == msg.id) != -1;
        if (!exists) {
          messages.add(msg);
          print(
              '[ChatRoom] Added new message to list. Total messages: ${messages.length}');
          loadReactionsForMessage(msg.id);
        } else {
          print('[ChatRoom] Message already exists, skipping');
        }
      }
    });

    _typingSub = _socket.onUserTyping.listen((name) {
      print('[ChatRoom] ✅ User typing: $name');
      typingUser.value = name;
    });

    _stopTypingSub = _socket.onUserStopTyping.listen((_) {
      print('[ChatRoom] ✅ User stopped typing');
      typingUser.value = '';
    });

    _editedSub = _socket.onMessageEdited.listen((data) {
      print('[ChatRoom] ✅ Message edited via socket: ${data['messageId']}');
      final mid = data['messageId']?.toString();
      final newContent = data['newContent']?.toString();
      if (mid != null && newContent != null) {
        final i = messages.indexWhere((m) => m.id == mid);
        if (i >= 0) {
          messages[i] = MessageModel(
            id: messages[i].id,
            chatId: messages[i].chatId,
            content: newContent,
            type: messages[i].type,
            senderId: messages[i].senderId,
            senderName: messages[i].senderName,
            createdAt: messages[i].createdAt,
            status: messages[i].status,
            isEdited: true,
          );
          messages.refresh();
          print('[ChatRoom] Updated message content');
        }
      }
    });

    _deletedSub = _socket.onMessageDeleted.listen((data) {
      print('[ChatRoom] ✅ Message deleted via socket: ${data['messageId']}');
      final mid = data['messageId']?.toString();
      if (mid != null) {
        messages.removeWhere((m) => m.id == mid);
        reactionsByMessage.remove(mid);
        print('[ChatRoom] Removed message from list');
      }
    });

    _pinnedSub = _socket.onMessagePinned.listen((data) {
      print('[ChatRoom] ✅ Message pinned via socket: ${data['messageId']}');
      if (data['chatId']?.toString() == cid) {
        pinnedMessage.value = PinnedMessageModel(
          messageId: data['messageId']?.toString() ?? '',
          content: data['messageContent']?.toString(),
          pinnedBy: data['pinnedBy']?.toString(),
          duration: data['duration']?.toString(),
          expiresAt: data['expiresAt'] != null
              ? DateTime.tryParse(data['expiresAt'].toString())
              : null,
        );
      }
    });

    _unpinnedSub = _socket.onMessageUnpinned.listen((mid) {
      print('[ChatRoom] ✅ Message unpinned via socket: $mid');
      if (pinnedMessage.value?.messageId == mid) {
        pinnedMessage.value = null;
      }
    });

    _statusSub = _socket.onMessageStatus.listen((data) {
      final chatId = data['chatId']?.toString();
      final messageId = data['messageId']?.toString();
      final status = data['status']?.toString();
      print(
          '[ChatRoom] ✅ Message status update via socket: $messageId -> $status');
      if (chatId == cid && messageId != null && status != null) {
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          final m = messages[idx];
          messages[idx] = MessageModel(
            id: m.id,
            chatId: m.chatId,
            content: m.content,
            type: m.type,
            senderId: m.senderId,
            senderName: m.senderName,
            createdAt: m.createdAt,
            status: status,
            replyToId: m.replyToId,
            replyToContent: m.replyToContent,
            replyToSender: m.replyToSender,
            fileUrl: m.fileUrl,
            fileName: m.fileName,
            fileSize: m.fileSize,
            fileType: m.fileType,
            isDeleted: m.isDeleted,
            isEdited: m.isEdited,
          );
          messages.refresh();
        }
      }
    });

    _reactionAddedSub = _socket.onReactionAdded.listen((data) {
      final socketChatId = data['chatId']?.toString();
      final mid = data['messageId']?.toString();
      final emoji = data['emoji']?.toString();
      final userId = data['userId']?.toString();

      print(
          '[ChatRoom] ✅ Reaction added via socket: messageId=$mid, emoji=$emoji, userId=$userId, currentChatId=$cid');

      if (socketChatId == cid && mid != null) {
        _handleReactionSocketUpdate(data, mid, isAdd: true);
        print('[ChatRoom] Applied optimistic reaction update');

        Future.delayed(const Duration(milliseconds: 100), () {
          loadReactionsForMessage(mid);
        });
      } else {
        print(
            '[ChatRoom] Skipping reaction - chatId mismatch: $socketChatId != $cid');
      }
    });

    _reactionRemovedSub = _socket.onReactionRemoved.listen((data) {
      final socketChatId = data['chatId']?.toString();
      final mid = data['messageId']?.toString();
      final emoji = data['emoji']?.toString();
      final userId = data['userId']?.toString();

      print(
          '[ChatRoom] ✅ Reaction removed via socket: messageId=$mid, emoji=$emoji, userId=$userId');

      if (socketChatId == cid && mid != null) {
        _handleReactionSocketUpdate(data, mid, isAdd: false);
        print('[ChatRoom] Applied optimistic reaction removal');

        Future.delayed(const Duration(milliseconds: 100), () {
          loadReactionsForMessage(mid);
        });
      }
    });

    print('[ChatRoom] Socket event subscriptions completed');
  }

  void _handleReactionSocketUpdate(Map<String, dynamic> data, String messageId,
      {required bool isAdd}) {
    final emoji = data['emoji']?.toString();
    final userId = data['userId']?.toString();
    final userName = data['userName']?.toString();

    if (emoji == null || userId == null) {
      print('[ChatRoom] Missing emoji or userId in reaction update');
      return;
    }

    final currentReactions =
        List<ReactionModel>.from(reactionsByMessage[messageId] ?? []);

    if (isAdd) {
      final existingIndex =
          currentReactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex >= 0) {
        final existing = currentReactions[existingIndex];
        if (!existing.userIds.contains(userId)) {
          final updatedUserIds = [...existing.userIds, userId];
          final updatedUserNames = List<String>.from(existing.userNames ?? []);
          if (userName != null) updatedUserNames.add(userName);

          currentReactions[existingIndex] = ReactionModel(
            emoji: emoji,
            userIds: updatedUserIds,
            userNames: updatedUserNames,
          );
          print('[ChatRoom] Added user to existing reaction: $emoji');
        }
      } else {
        currentReactions.add(ReactionModel(
          emoji: emoji,
          userIds: [userId],
          userNames: userName != null ? [userName] : null,
        ));
        print('[ChatRoom] Created new reaction: $emoji');
      }
    } else {
      final existingIndex =
          currentReactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex >= 0) {
        final existing = currentReactions[existingIndex];
        final updatedUserIds =
            existing.userIds.where((id) => id != userId).toList();

        if (updatedUserIds.isEmpty) {
          currentReactions.removeAt(existingIndex);
          print('[ChatRoom] Removed reaction completely: $emoji');
        } else {
          final updatedUserNames = existing.userNames
              ?.where((name) =>
                  existing.userIds.indexOf(name) !=
                  existing.userIds.indexOf(userId))
              .toList()
              .cast<String>();

          currentReactions[existingIndex] = ReactionModel(
            emoji: emoji,
            userIds: updatedUserIds,
            userNames: updatedUserNames,
          );
          print('[ChatRoom] Removed user from reaction: $emoji');
        }
      }
    }

    reactionsByMessage[messageId] = currentReactions;
    reactionsByMessage.refresh();
    print(
        '[ChatRoom] Reaction map updated and refreshed. Total reactions: ${currentReactions.length}');
  }

  Future<void> _loadChat(String id) async {
    try {
      chat.value = await _chatRepo.getChat(id);
      print('[ChatRoom] getChat success: chatId=$id, name=${chat.value?.name}');
    } catch (e) {
      showApiError(e);
    }
  }

  Future<void> _loadMessages(String id) async {
    isLoading.value = true;
    error.value = '';
    try {
      final list = await _chatRepo.getMessages(id);
      print('[ChatRoom] getMessages success: chatId=$id, count=${list.length}');

      final enriched = list.map((m) {
        if (m.senderId != currentUserId || (m.readReceipts == null)) {
          return m;
        }
        final others =
            m.readReceipts!.where((r) => r.userId != currentUserId).toList();
        final status = others.isNotEmpty ? 'seen' : 'sent';
        return MessageModel(
          id: m.id,
          chatId: m.chatId,
          content: m.content,
          type: m.type,
          senderId: m.senderId,
          senderName: m.senderName,
          createdAt: m.createdAt,
          status: status,
          replyToId: m.replyToId,
          replyToContent: m.replyToContent,
          replyToSender: m.replyToSender,
          fileUrl: m.fileUrl,
          fileName: m.fileName,
          fileSize: m.fileSize,
          fileType: m.fileType,
          isDeleted: m.isDeleted,
          isEdited: m.isEdited,
          editedAt: m.editedAt,
          originalContent: m.originalContent,
          readReceipts: m.readReceipts,
        );
      }).toList();

      messages.assignAll(enriched);

      _loadAllReactionsInBackground(enriched);

      final toMark = list
          .where((m) => m.senderId != currentUserId)
          .map((m) => m.id)
          .toList();
      if (toMark.isNotEmpty) {
        await _chatRepo.markMessagesRead(id, toMark);
        if (chat.value?.isGroup == true) {
          _socket.markGroupMessagesSeen(id, toMark);
        } else {
          for (final m in list.where((m) => m.senderId != currentUserId)) {
            _socket.markMessageSeen(id, m.id, m.senderId);
          }
        }
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

  void _loadAllReactionsInBackground(List<MessageModel> messages) {
    if (messages.isEmpty) return;

    Future.microtask(() async {
      try {
        const batchSize = 10;
        for (var i = 0; i < messages.length; i += batchSize) {
          final batch = messages.skip(i).take(batchSize).toList();
          await Future.wait(
            batch.map((msg) => loadReactionsForMessage(msg.id)),
            eagerError: false,
          );
          if (i + batchSize < messages.length) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        print('[ChatRoom] Loaded reactions for ${messages.length} messages');
      } catch (e) {
        print('[ChatRoom] Error loading reactions in background: $e');
      }
    });
  }

  Future<void> loadReactionsForMessage(String messageId) async {
    try {
      final list = await _reactionsRepo.getReactions(chatId, messageId);

      reactionsByMessage[messageId] = list;

      reactionsByMessage.refresh();

      print(
          '[ChatRoom] Loaded ${list.length} reactions for message $messageId');
    } catch (e) {
      print('[ChatRoom] loadReactionsForMessage error for $messageId: $e');
      if (!reactionsByMessage.containsKey(messageId)) {
        reactionsByMessage[messageId] = [];
      }
    }
  }

  Future<void> _loadPinned(String id) async {
    try {
      pinnedMessage.value = await _chatRepo.getPinnedMessage(id);
      print(
          '[ChatRoom] getPinnedMessage success: chatId=$id, pinned=${pinnedMessage.value?.messageId}');
    } catch (e) {
      showApiError(e);
    }
  }

  // Future<void> sendText(String content,
  //     {String? replyToId,
  //     String? replyToContent,
  //     String? replyToSender}) async {
  //   if (chatId.isEmpty || content.trim().isEmpty) return;
  //   sending.value = true;
  //   error.value = '';
  //   try {
  //     final msg = await _chatRepo.sendMessage(chatId,
  //         content: content.trim(), replyToId: replyToId);
  //     print(
  //         '[ChatRoom] sendMessage success: messageId=${msg.id}, chatId=$chatId');
  //     messages.add(msg);
  //     _socket.sendMessage(chatId, content.trim(),
  //         messageId: msg.id,
  //         replyToId: replyToId,
  //         replyToContent: replyToContent,
  //         replyToSender: replyToSender);
  //   } on ApiException catch (e) {
  //     error.value = e.message;
  //     showApiError(e);
  //   } catch (e) {
  //     error.value = e.toString();
  //     showApiError(e);
  //   } finally {
  //     sending.value = false;
  //   }
  // }

  Future<void> sendText(String content,
      {String? replyToId,
      String? replyToContent,
      String? replyToSender}) async {
    if (chatId.isEmpty || content.trim().isEmpty) return;
    sending.value = true;
    error.value = '';
    try {
      final msg = await _chatRepo.sendMessage(chatId,
          content: content.trim(), replyToId: replyToId);
      print(
          '[ChatRoom] sendMessage success: messageId=${msg.id}, chatId=$chatId');

      _socket.sendMessage(chatId, content.trim(),
          messageId: msg.id,
          replyToId: replyToId,
          replyToContent: replyToContent,
          replyToSender: replyToSender);
    } on ApiException catch (e) {
      error.value = e.message;
      showApiError(e);
    } catch (e) {
      error.value = e.toString();
      showApiError(e);
    } finally {
      sending.value = false;
    }
  }

  void sendTyping() => _socket.sendTyping(chatId);
  void stopTyping() => _socket.sendStopTyping(chatId);

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _chatRepo.editMessage(chatId, messageId, newContent);
      print('[ChatRoom] editMessage success: messageId=$messageId');
      _socket.editMessage(
          chatId, messageId, newContent, DateTime.now().toIso8601String(), '');
    } catch (e) {
      showApiError(e);
    }
  }

  Future<void> deleteMessage(String messageId,
      {bool deleteForEveryone = false}) async {
    try {
      await _chatRepo.deleteMessage(chatId, messageId,
          deleteForEveryone: deleteForEveryone);
      print('[ChatRoom] deleteMessage success: messageId=$messageId');
      _socket.deleteMessage(chatId, messageId, deleteForEveryone);
      messages.removeWhere((m) => m.id == messageId);
      reactionsByMessage.remove(messageId);
    } catch (e) {
      showApiError(e);
    }
  }

  Future<void> pinMessage(String messageId, String duration) async {
    try {
      final msg = messages.firstWhereOrNull((m) => m.id == messageId);
      await _chatRepo.pinMessage(chatId, messageId, duration);
      print('[ChatRoom] pinMessage success: messageId=$messageId');
      _socket.pinMessage(chatId, messageId, duration, '', msg?.content ?? '',
          msg?.senderName ?? '');
      await _loadPinned(chatId);
    } catch (e) {
      showApiError(e);
    }
  }

  Future<void> unpinMessage(String messageId) async {
    try {
      await _chatRepo.unpinMessage(chatId, messageId);
      print('[ChatRoom] unpinMessage success: messageId=$messageId');
      _socket.unpinMessage(chatId, messageId);
      pinnedMessage.value = null;
    } catch (e) {
      showApiError(e);
    }
  }

  void openGroupInfo() {
    final chatValue = chat.value;
    if (chatValue == null) return;

    final groupId =
        chatValue.groupId ?? (chatValue.isGroup ? chatValue.id : null);
    if (groupId != null) {
      Get.toNamed(AppRoutes.groupInfo,
          arguments: {'groupId': groupId, 'chatId': chatId});
    } else {
      print(
          '[ChatRoom] openGroupInfo: Cannot open - groupId is null and chat is not a group');
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final existing = reactionsByMessage[messageId] ?? [];
    final myId = currentUserId;

    final target = existing.firstWhereOrNull((r) => r.emoji == emoji);
    final hasReacted = target != null && target.userIds.contains(myId);

    print(
        '[ChatRoom] toggleReaction: messageId=$messageId, emoji=$emoji, hasReacted=$hasReacted');

    _updateReactionOptimistically(messageId, emoji, hasReacted);

    try {
      if (hasReacted) {
        await _reactionsRepo.removeReaction(chatId, messageId, emoji);
        print(
            '[ChatRoom] API: Reaction removed: messageId=$messageId, emoji=$emoji');
        _socket.removeReaction(chatId, messageId, emoji);
      } else {
        await _reactionsRepo.addReaction(chatId, messageId, emoji);
        print(
            '[ChatRoom] API: Reaction added: messageId=$messageId, emoji=$emoji');
        _socket.addReaction(chatId, messageId, emoji);
      }

      _debouncedReactionRefresh(messageId);
    } catch (e) {
      print('[ChatRoom] toggleReaction error: $e');
      showApiError(e);

      _updateReactionOptimistically(messageId, emoji, !hasReacted);
    }
  }

  void _updateReactionOptimistically(
      String messageId, String emoji, bool isRemoving) {
    final currentReactions =
        List<ReactionModel>.from(reactionsByMessage[messageId] ?? []);
    final myId = currentUserId;
    final myName = currentUserName;

    if (isRemoving) {
      final index = currentReactions.indexWhere((r) => r.emoji == emoji);
      if (index >= 0) {
        final reaction = currentReactions[index];
        final updatedUserIds =
            reaction.userIds.where((id) => id != myId).toList();

        if (updatedUserIds.isEmpty) {
          currentReactions.removeAt(index);
        } else {
          currentReactions[index] = ReactionModel(
            emoji: emoji,
            userIds: updatedUserIds,
            userNames: reaction.userNames
                ?.where((name) =>
                    reaction.userIds.indexOf(name) !=
                    reaction.userIds.indexOf(myId))
                .toList()
                .cast<String>(),
          );
        }
      }
    } else {
      final index = currentReactions.indexWhere((r) => r.emoji == emoji);
      if (index >= 0) {
        final reaction = currentReactions[index];
        if (!reaction.userIds.contains(myId)) {
          currentReactions[index] = ReactionModel(
            emoji: emoji,
            userIds: [...reaction.userIds, myId],
            userNames: [...List<String>.from(reaction.userNames ?? []), myName],
          );
        }
      } else {
        currentReactions.add(ReactionModel(
          emoji: emoji,
          userIds: [myId],
          userNames: [myName],
        ));
      }
    }

    reactionsByMessage[messageId] = currentReactions;
    reactionsByMessage.refresh();
    print('[ChatRoom] Optimistic reaction update completed');
  }

  Timer? _reactionRefreshTimer;
  final Map<String, DateTime> _lastRefreshTime = {};

  void _debouncedReactionRefresh(String messageId) {
    final lastRefresh = _lastRefreshTime[messageId];
    final now = DateTime.now();

    if (lastRefresh != null &&
        now.difference(lastRefresh).inMilliseconds < 500) {
      return;
    }

    _reactionRefreshTimer?.cancel();
    _reactionRefreshTimer = Timer(const Duration(milliseconds: 300), () {
      loadReactionsForMessage(messageId);
      _lastRefreshTime[messageId] = DateTime.now();
    });
  }

  @override
  void onClose() {
    print('[ChatRoom] Closing controller and cleaning up subscriptions');
    if (chatId.isNotEmpty) _socket.leaveChat(chatId);
    _receiveSub?.cancel();
    _typingSub?.cancel();
    _stopTypingSub?.cancel();
    _editedSub?.cancel();
    _deletedSub?.cancel();
    _pinnedSub?.cancel();
    _unpinnedSub?.cancel();
    _statusSub?.cancel();
    _reactionAddedSub?.cancel();
    _reactionRemovedSub?.cancel();
    _reactionRefreshTimer?.cancel();
    super.onClose();
  }
}
