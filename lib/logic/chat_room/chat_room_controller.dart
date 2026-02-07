// import 'dart:async';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:softex_chat_app/data/models/reaction_model.dart';
// import '../../data/models/chat_model.dart';
// import '../../data/models/message_model.dart';
// import '../../data/models/pinned_message_model.dart';
// import '../../data/repositories/chat_repository.dart';
// import '../../services/socket_service.dart';
// import '../../services/storage_service.dart';

// class ChatRoomController extends GetxController {
//   final ChatRepository _repository = ChatRepository();
//   final SocketService _socketService = Get.find<SocketService>();

//   final String chatId;
//   ChatRoomController({required this.chatId});

//   // Reactive state
//   final RxBool isLoading = true.obs;
//   final RxString error = ''.obs;
//   final Rx<ChatModel?> chat = Rx<ChatModel?>(null);
//   final RxList<MessageModel> messages = <MessageModel>[].obs;
//   final Rx<PinnedMessageModel?> pinnedMessage = Rx<PinnedMessageModel?>(null);
//   final RxString typingUser = ''.obs;

//   // Reply state
//   final Rx<MessageModel?> replyingToMessage = Rx<MessageModel?>(null);

//   // CRITICAL: Proper reactive maps for real-time updates
//   final RxMap<String, RxList<ReactionModel>> reactionsByMessage =
//       <String, RxList<ReactionModel>>{}.obs;
//   final RxMap<String, RxList<ReadReceiptModel>> readReceiptsByMessage =
//       <String, RxList<ReadReceiptModel>>{}.obs;
//   final RxMap<String, RxBool> participantOnlineStatus = <String, RxBool>{}.obs;
//   final RxMap<String, Rx<DateTime?>> participantLastSeen =
//       <String, Rx<DateTime?>>{}.obs;

//   // Subscriptions
//   StreamSubscription? _receiveMessageSub;
//   StreamSubscription? _messageStatusSub;
//   StreamSubscription? _typingSub;
//   StreamSubscription? _stopTypingSub;
//   StreamSubscription? _pinnedSub;
//   StreamSubscription? _unpinnedSub;
//   StreamSubscription? _editedSub;
//   StreamSubscription? _deletedSub;
//   StreamSubscription? _reactionAddedSub;
//   StreamSubscription? _reactionRemovedSub;
//   StreamSubscription? _onlineStatusSub;

//   Timer? _typingTimer;

//   String get currentUserId => StorageService.userId ?? '';

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeParticipantStatus();
//     _subscribeToSocketEvents();
//     _loadChatData();
//   }

//   @override
//   void onClose() {
//     print('[ChatRoom] Closing controller and cleaning up subscriptions');
//     _typingTimer?.cancel();
//     _receiveMessageSub?.cancel();
//     _messageStatusSub?.cancel();
//     _typingSub?.cancel();
//     _stopTypingSub?.cancel();
//     _pinnedSub?.cancel();
//     _unpinnedSub?.cancel();
//     _editedSub?.cancel();
//     _deletedSub?.cancel();
//     _reactionAddedSub?.cancel();
//     _reactionRemovedSub?.cancel();
//     _onlineStatusSub?.cancel();
//     _socketService.leaveChat(chatId);
//     super.onClose();
//   }

//   void _initializeParticipantStatus() {
//     final participants = chat.value?.participants ?? [];
//     for (final p in participants) {
//       participantOnlineStatus[p.id] = RxBool(p.isOnline ?? false);
//       participantLastSeen[p.id] = Rx<DateTime?>(p.lastSeen);
//     }
//     print(
//         '[ChatRoom] Initialized status for ${participants.length} participants');
//   }

//   void _subscribeToSocketEvents() {
//     print('[ChatRoom] Subscribing to socket events for chat: $chatId');
//     _socketService.joinChat(chatId);
//     _socketService.subscribeChatRoom(chatId);

//     _receiveMessageSub = _socketService.onReceiveMessage.listen((msg) {
//       if (msg.chatId == chatId) {
//         print(
//             '[ChatRoom] ✅ Received message via socket: ${msg.id}, content: ${msg.content}');
//         _handleReceivedMessage(msg);
//       }
//     });

//     _messageStatusSub = _socketService.onMessageStatus.listen((data) {
//       if (data['chatId'] == chatId) {
//         print(
//             '[ChatRoom] ✅ Message status update: ${data['messageId']} -> ${data['status']}');
//         _handleMessageStatusUpdate(data);
//       }
//     });

//     _typingSub = _socketService.onUserTyping.listen((userName) {
//       if (userName != StorageService.userName) {
//         typingUser.value = userName;
//         print('[ChatRoom] 👀 User typing: $userName');
//       }
//     });

//     _stopTypingSub = _socketService.onUserStopTyping.listen((_) {
//       typingUser.value = '';
//       print('[ChatRoom] User stopped typing');
//     });

//     _pinnedSub = _socketService.onMessagePinned.listen((data) {
//       if (data['chatId'] == chatId) {
//         print('[ChatRoom] ✅ Message pinned: ${data['messageId']}');
//         _handleMessagePinned(data);
//       }
//     });

//     _unpinnedSub = _socketService.onMessageUnpinned.listen((messageId) {
//       print('[ChatRoom] ✅ Message unpinned: $messageId');
//       pinnedMessage.value = null;
//     });

//     _editedSub = _socketService.onMessageEdited.listen((data) {
//       if (data['chatId'] == chatId) {
//         print('[ChatRoom] ✅ Message edited via socket: ${data['messageId']}');
//         _handleMessageEdited(data);
//       }
//     });

//     _deletedSub = _socketService.onMessageDeleted.listen((data) {
//       if (data['chatId'] == chatId) {
//         print('[ChatRoom] ✅ Message deleted via socket: ${data['messageId']}');
//         _handleMessageDeleted(data);
//       }
//     });

//     _reactionAddedSub = _socketService.onReactionAdded.listen((data) {
//       if (data['chatId'] == chatId) {
//         print(
//             '[ChatRoom] ✅ Reaction added via socket: ${data['emoji']} to ${data['messageId']}');
//         _handleReactionAdded(data);
//       }
//     });

//     _reactionRemovedSub = _socketService.onReactionRemoved.listen((data) {
//       if (data['chatId'] == chatId) {
//         print(
//             '[ChatRoom] ✅ Reaction removed via socket: ${data['emoji']} from ${data['messageId']}');
//         _handleReactionRemoved(data);
//       }
//     });

//     _onlineStatusSub = _socketService.onUserOnlineStatus.listen((data) {
//       final userId = data['userId']?.toString();
//       final isOnline = data['isOnline'] as bool?;
//       final lastSeenStr = data['lastSeen']?.toString();

//       if (userId != null) {
//         print('[ChatRoom] ✅ User online status: $userId -> $isOnline');
//         if (participantOnlineStatus.containsKey(userId)) {
//           participantOnlineStatus[userId]!.value = isOnline ?? false;
//         } else {
//           participantOnlineStatus[userId] = RxBool(isOnline ?? false);
//         }

//         if (lastSeenStr != null) {
//           final lastSeen = DateTime.tryParse(lastSeenStr);
//           if (participantLastSeen.containsKey(userId)) {
//             participantLastSeen[userId]!.value = lastSeen;
//           } else {
//             participantLastSeen[userId] = Rx<DateTime?>(lastSeen);
//           }
//         }
//       }
//     });

//     print('[ChatRoom] Socket event subscriptions completed');
//   }

//   Future<void> _loadChatData() async {
//     try {
//       isLoading.value = true;
//       error.value = '';

//       final results = await Future.wait([
//         _repository.getChat(chatId),
//         _repository.getPinnedMessage(chatId),
//         _repository.getMessages(chatId),
//       ]);

//       chat.value = results[0] as ChatModel;
//       pinnedMessage.value = results[1] as PinnedMessageModel?;
//       final msgs = results[2] as List<MessageModel>;

//       messages.value = msgs;
//       print('[ChatRoom] Loaded ${msgs.length} messages');

//       _initializeParticipantStatus();

//       // Load reactions for all messages
//       await _loadReactionsForMessages(msgs);

//       // Initialize read receipts
//       _initializeReadReceipts(msgs);

//       // Mark messages as read
//       final unreadIds = msgs
//           .where((m) => m.senderId != currentUserId)
//           .map((m) => m.id)
//           .toList();

//       if (unreadIds.isNotEmpty) {
//         await _markMessagesAsRead(unreadIds);
//       }

//       isLoading.value = false;
//     } catch (e) {
//       error.value = e.toString();
//       isLoading.value = false;
//       print('[ChatRoom] Error loading chat data: $e');
//     }
//   }

//   Future<void> _loadReactionsForMessages(List<MessageModel> msgs) async {
//     for (final msg in msgs) {
//       try {
//         final reactionsResponse =
//             await _repository.getReactions(chatId, msg.id);
//         final reactions = reactionsResponse
//             .map((json) => ReactionModel.fromJson(json))
//             .toList();

//         // Create or update reactive list
//         if (reactionsByMessage.containsKey(msg.id)) {
//           reactionsByMessage[msg.id]!.value = reactions;
//         } else {
//           reactionsByMessage[msg.id] = RxList<ReactionModel>(reactions);
//         }

//         print(
//             '[ChatRoom] ✅ Loaded ${reactions.length} reactions for message ${msg.id}');
//       } catch (e) {
//         print('[ChatRoom] ⚠️ Error loading reactions for ${msg.id}: $e');
//         reactionsByMessage[msg.id] = RxList<ReactionModel>([]);
//       }
//     }
//     print('[ChatRoom] Loaded reactions for ${msgs.length} messages');
//   }

//   void _initializeReadReceipts(List<MessageModel> msgs) {
//     for (final msg in msgs) {
//       if (msg.readReceipts != null && msg.readReceipts!.isNotEmpty) {
//         readReceiptsByMessage[msg.id] =
//             RxList<ReadReceiptModel>(msg.readReceipts!);
//       } else {
//         readReceiptsByMessage[msg.id] = RxList<ReadReceiptModel>([]);
//       }
//     }
//   }

//   Future<void> _markMessagesAsRead(List<String> messageIds) async {
//     try {
//       await _repository.markMessagesRead(chatId, messageIds);

//       // Emit socket event
//       if (chat.value?.isGroup == true) {
//         _socketService.markGroupMessagesSeen(chatId, messageIds);
//       } else {
//         for (final msgId in messageIds) {
//           final msg = messages.firstWhereOrNull((m) => m.id == msgId);
//           if (msg != null) {
//             _socketService.markMessageSeen(chatId, msgId, msg.senderId);
//           }
//         }
//       }
//     } catch (e) {
//       print('[ChatRoom] Error marking messages as read: $e');
//     }
//   }

//   void _handleReceivedMessage(MessageModel msg) {
//     final existingIndex = messages.indexWhere((m) => m.id == msg.id);

//     if (existingIndex == -1) {
//       messages.add(msg);
//       print(
//           '[ChatRoom] Added new message to list. Total messages: ${messages.length}');

//       // Initialize empty reactions/receipts for new message
//       reactionsByMessage[msg.id] = RxList<ReactionModel>([]);
//       readReceiptsByMessage[msg.id] = RxList<ReadReceiptModel>([]);

//       // Mark as read if from another user
//       if (msg.senderId != currentUserId) {
//         _markMessagesAsRead([msg.id]);
//       }
//     }
//   }

//   void _handleMessageStatusUpdate(Map<String, dynamic> data) {
//     final messageId = data['messageId']?.toString();
//     final status = data['status']?.toString();
//     final userId = data['userId']?.toString();
//     final userName = data['userName']?.toString();
//     final readAt = data['readAt']?.toString();

//     if (messageId == null) return;

//     // Update message status
//     final msgIndex = messages.indexWhere((m) => m.id == messageId);
//     if (msgIndex != -1) {
//       final updatedMsg = MessageModel(
//         id: messages[msgIndex].id,
//         chatId: messages[msgIndex].chatId,
//         content: messages[msgIndex].content,
//         type: messages[msgIndex].type,
//         senderId: messages[msgIndex].senderId,
//         senderName: messages[msgIndex].senderName,
//         createdAt: messages[msgIndex].createdAt,
//         status: status ?? messages[msgIndex].status,
//         replyToId: messages[msgIndex].replyToId,
//         replyToContent: messages[msgIndex].replyToContent,
//         replyToSender: messages[msgIndex].replyToSender,
//         fileUrl: messages[msgIndex].fileUrl,
//         fileName: messages[msgIndex].fileName,
//         fileSize: messages[msgIndex].fileSize,
//         fileType: messages[msgIndex].fileType,
//         isDeleted: messages[msgIndex].isDeleted,
//         isEdited: messages[msgIndex].isEdited,
//         editedAt: messages[msgIndex].editedAt,
//         originalContent: messages[msgIndex].originalContent,
//         readReceipts: messages[msgIndex].readReceipts,
//       );
//       messages[msgIndex] = updatedMsg;
//     }

//     // Update read receipts if this is a 'seen' status
//     if (status == 'seen' && userId != null) {
//       if (!readReceiptsByMessage.containsKey(messageId)) {
//         readReceiptsByMessage[messageId] = RxList<ReadReceiptModel>([]);
//       }

//       final receipt = ReadReceiptModel(
//         userId: userId,
//         userName: userName,
//         readAt: readAt != null ? DateTime.tryParse(readAt) : DateTime.now(),
//       );

//       // Check if receipt already exists
//       final existingIndex = readReceiptsByMessage[messageId]!
//           .indexWhere((r) => r.userId == userId);
//       if (existingIndex == -1) {
//         readReceiptsByMessage[messageId]!.add(receipt);
//         print(
//             '[ChatRoom] ✅ Added read receipt for message $messageId by user $userId');
//       }
//     }
//   }

//   void _handleMessagePinned(Map<String, dynamic> data) {
//     final msgId = data['messageId']?.toString();
//     final content = data['messageContent']?.toString() ?? '';
//     final expiresAtStr = data['expiresAt']?.toString();

//     if (msgId != null) {
//       pinnedMessage.value = PinnedMessageModel(
//         messageId: msgId,
//         content: content,
//         expiresAt:
//             expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
//       );
//     }
//   }

//   void _handleMessageEdited(Map<String, dynamic> data) {
//     final messageId = data['messageId']?.toString();
//     final newContent = data['newContent']?.toString();
//     final editedAtStr = data['editedAt']?.toString();

//     if (messageId == null || newContent == null) return;

//     final msgIndex = messages.indexWhere((m) => m.id == messageId);
//     if (msgIndex != -1) {
//       final oldMsg = messages[msgIndex];
//       final updatedMsg = MessageModel(
//         id: oldMsg.id,
//         chatId: oldMsg.chatId,
//         content: newContent,
//         type: oldMsg.type,
//         senderId: oldMsg.senderId,
//         senderName: oldMsg.senderName,
//         createdAt: oldMsg.createdAt,
//         status: oldMsg.status,
//         replyToId: oldMsg.replyToId,
//         replyToContent: oldMsg.replyToContent,
//         replyToSender: oldMsg.replyToSender,
//         fileUrl: oldMsg.fileUrl,
//         fileName: oldMsg.fileName,
//         fileSize: oldMsg.fileSize,
//         fileType: oldMsg.fileType,
//         isDeleted: oldMsg.isDeleted,
//         isEdited: true,
//         editedAt: editedAtStr != null
//             ? DateTime.tryParse(editedAtStr)
//             : DateTime.now(),
//         originalContent: oldMsg.originalContent ?? oldMsg.content,
//         readReceipts: oldMsg.readReceipts,
//       );
//       messages[msgIndex] = updatedMsg;
//     }
//   }

//   void _handleMessageDeleted(Map<String, dynamic> data) {
//     final messageId = data['messageId']?.toString();
//     final deleteForEveryone = data['deleteForEveryone'] as bool? ?? false;

//     if (messageId == null) return;

//     if (deleteForEveryone) {
//       messages.removeWhere((m) => m.id == messageId);
//       reactionsByMessage.remove(messageId);
//       readReceiptsByMessage.remove(messageId);
//     } else {
//       // Only remove if it's my message
//       final msgIndex = messages
//           .indexWhere((m) => m.id == messageId && m.senderId == currentUserId);
//       if (msgIndex != -1) {
//         messages.removeAt(msgIndex);
//         reactionsByMessage.remove(messageId);
//         readReceiptsByMessage.remove(messageId);
//       }
//     }
//   }

//   void _handleReactionAdded(Map<String, dynamic> data) {
//     final messageId = data['messageId']?.toString();
//     final emoji = data['emoji']?.toString();
//     final userId = data['userId']?.toString();
//     final userName = data['userName']?.toString();

//     if (messageId == null || emoji == null || userId == null) return;

//     // Initialize if doesn't exist
//     if (!reactionsByMessage.containsKey(messageId)) {
//       reactionsByMessage[messageId] = RxList<ReactionModel>([]);
//     }

//     final reactions = reactionsByMessage[messageId]!;
//     final existingReactionIndex = reactions.indexWhere((r) => r.emoji == emoji);

//     if (existingReactionIndex != -1) {
//       // Add user to existing reaction
//       final existing = reactions[existingReactionIndex];
//       if (!existing.userIds.contains(userId)) {
//         final updatedUserIds = [...existing.userIds, userId];
//         final updatedUserNames = existing.userNames != null
//             ? [...existing.userNames!, if (userName != null) userName]
//             : (userName != null ? [userName] : null);

//         reactions[existingReactionIndex] = ReactionModel(
//           emoji: emoji,
//           userIds: updatedUserIds,
//           userNames: updatedUserNames,
//         );
//       }
//     } else {
//       // Create new reaction
//       reactions.add(ReactionModel(
//         emoji: emoji,
//         userIds: [userId],
//         userNames: userName != null ? [userName] : null,
//       ));
//     }

//     // Force update
//     reactionsByMessage[messageId] = reactions;
//     print(
//         '[ChatRoom] ✅ Reaction added: $emoji by $userId to message $messageId. Total reactions: ${reactions.length}');
//   }

//   void _handleReactionRemoved(Map<String, dynamic> data) {
//     final messageId = data['messageId']?.toString();
//     final emoji = data['emoji']?.toString();
//     final userId = data['userId']?.toString();

//     if (messageId == null || emoji == null || userId == null) return;

//     if (!reactionsByMessage.containsKey(messageId)) return;

//     final reactions = reactionsByMessage[messageId]!;
//     final reactionIndex = reactions.indexWhere((r) => r.emoji == emoji);

//     if (reactionIndex != -1) {
//       final existing = reactions[reactionIndex];
//       final updatedUserIds =
//           existing.userIds.where((id) => id != userId).toList();

//       if (updatedUserIds.isEmpty) {
//         reactions.removeAt(reactionIndex);
//       } else {
//         final updatedUserNames = existing.userNames
//             ?.where((name) =>
//                 existing.userIds.indexOf(name) !=
//                 existing.userIds.indexOf(userId))
//             .toList();

//         reactions[reactionIndex] = ReactionModel(
//           emoji: emoji,
//           userIds: updatedUserIds,
//           userNames: updatedUserNames,
//         );
//       }

//       reactionsByMessage[messageId] = reactions;
//       print(
//           '[ChatRoom] ✅ Reaction removed: $emoji by $userId from message $messageId');
//     }
//   }

//   // User actions
//   Future<void> sendText(String content, {String? replyToId}) async {
//     try {
//       final msg = await _repository.sendMessage(
//         chatId,
//         content: content,
//         replyToId: replyToId ?? replyingToMessage.value?.id,
//       );

//       // Clear reply state
//       replyingToMessage.value = null;

//       print(
//           '[ChatRoom] sendMessage success: messageId=${msg.id}, chatId=$chatId');
//     } catch (e) {
//       print('[ChatRoom] Error sending message: $e');
//       Get.snackbar('Error', 'Failed to send message');
//     }
//   }

//   Future<void> sendFile({
//     required String fileUrl,
//     required String fileName,
//     required int fileSize,
//     required String fileType,
//     String type = 'image',
//   }) async {
//     try {
//       await _repository.sendMessage(
//         chatId,
//         content: fileName,
//         type: type,
//         fileUrl: fileUrl,
//         fileName: fileName,
//         fileSize: fileSize,
//         fileType: fileType,
//         replyToId: replyingToMessage.value?.id,
//       );

//       // Clear reply state
//       replyingToMessage.value = null;

//       print('[ChatRoom] File sent successfully');
//     } catch (e) {
//       print('[ChatRoom] Error sending file: $e');
//       Get.snackbar('Error', 'Failed to send file');
//     }
//   }

//   Future<void> editMessage(String messageId, String newContent) async {
//     try {
//       await _repository.editMessage(chatId, messageId, newContent);
//       print('[ChatRoom] Message edited successfully');
//     } catch (e) {
//       print('[ChatRoom] Error editing message: $e');
//       Get.snackbar('Error', 'Failed to edit message');
//     }
//   }

//   Future<void> deleteMessage(String messageId,
//       {bool deleteForEveryone = false}) async {
//     try {
//       await _repository.deleteMessage(chatId, messageId,
//           deleteForEveryone: deleteForEveryone);
//       print('[ChatRoom] Message deleted successfully');
//     } catch (e) {
//       print('[ChatRoom] Error deleting message: $e');
//       Get.snackbar('Error', 'Failed to delete message');
//     }
//   }

//   Future<void> toggleReaction(String messageId, String emoji) async {
//     try {
//       // Optimistically update UI
//       if (!reactionsByMessage.containsKey(messageId)) {
//         reactionsByMessage[messageId] = RxList<ReactionModel>([]);
//       }

//       final reactions = reactionsByMessage[messageId]!;
//       final existingReactionIndex =
//           reactions.indexWhere((r) => r.emoji == emoji);

//       bool isRemoving = false;
//       if (existingReactionIndex != -1) {
//         final existing = reactions[existingReactionIndex];
//         if (existing.userIds.contains(currentUserId)) {
//           isRemoving = true;
//         }
//       }

//       if (isRemoving) {
//         await _repository.removeReaction(chatId, messageId, emoji);
//       } else {
//         await _repository.addReaction(chatId, messageId, emoji);
//       }

//       print('[ChatRoom] Reaction toggled successfully');
//     } catch (e) {
//       print('[ChatRoom] Error toggling reaction: $e');
//       Get.snackbar('Error', 'Failed to update reaction');
//     }
//   }

//   Future<void> pinMessage(String messageId, String duration) async {
//     try {
//       await _repository.pinMessage(chatId, messageId, duration);
//       print('[ChatRoom] Message pinned successfully');
//     } catch (e) {
//       print('[ChatRoom] Error pinning message: $e');
//       Get.snackbar('Error', 'Failed to pin message');
//     }
//   }

//   Future<void> unpinMessage(String messageId) async {
//     try {
//       await _repository.unpinMessage(chatId, messageId);
//       print('[ChatRoom] Message unpinned successfully');
//     } catch (e) {
//       print('[ChatRoom] Error unpinning message: $e');
//       Get.snackbar('Error', 'Failed to unpin message');
//     }
//   }

//   void sendTyping() {
//     _socketService.sendTyping(chatId);
//     _typingTimer?.cancel();
//     _typingTimer = Timer(const Duration(seconds: 3), () {
//       _socketService.sendStopTyping(chatId);
//     });
//   }

//   void stopTyping() {
//     _typingTimer?.cancel();
//     _socketService.sendStopTyping(chatId);
//   }

//   void setReplyMessage(MessageModel? message) {
//     replyingToMessage.value = message;
//   }

//   void cancelReply() {
//     replyingToMessage.value = null;
//   }

//   void copyMessage(String content) {
//     Clipboard.setData(ClipboardData(text: content));
//     Get.snackbar('Copied', 'Message copied to clipboard');
//   }

//   void forwardMessage(MessageModel message) {
//     // Navigate to chat selection screen
//     Get.toNamed('/forward-message', arguments: {'message': message});
//   }

//   void openGroupInfo() {
//     if (chat.value?.isGroup == true) {
//       Get.toNamed('/group-info', arguments: {'chatId': chatId});
//     }
//   }
// }

import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/pinned_message_model.dart';
import '../../data/models/reaction_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';

class ChatRoomController extends GetxController {
  final String chatId;
  final ChatRepository _repo = ChatRepository();
  final SocketService _socket = Get.find<SocketService>();

  ChatRoomController({required this.chatId});

  // Reactive state
  final Rx<ChatModel?> chat = Rx<ChatModel?>(null);
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final Rx<PinnedMessageModel?> pinnedMessage = Rx<PinnedMessageModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString typingUser = ''.obs;

  // CRITICAL FIX: Online status tracking with individual Rx wrappers
  final RxMap<String, Rx<bool>> participantOnlineStatus =
      <String, Rx<bool>>{}.obs;
  final RxMap<String, Rx<DateTime?>> participantLastSeen =
      <String, Rx<DateTime?>>{}.obs;

  // CRITICAL FIX: Reactions map with RxList values
  final RxMap<String, RxList<ReactionModel>> reactionsByMessage =
      <String, RxList<ReactionModel>>{}.obs;

  // Read receipts map
  final RxMap<String, RxList<ReadReceiptModel>> readReceiptsByMessage =
      <String, RxList<ReadReceiptModel>>{}.obs;

  // Message statuses
  final RxMap<String, String> messageStatuses = <String, String>{}.obs;

  // CRITICAL FIX: Reply state (was named incorrectly)
  final Rx<MessageModel?> replyingToMessage = Rx<MessageModel?>(null);

  String get currentUserId => StorageService.userId ?? '';
  String get currentUserName => StorageService.userName ?? '';

  Timer? _typingTimer;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _subscribeToSocketEvents();
  }

  @override
  void onClose() {
    print('[ChatRoom] Closing controller and cleaning up subscriptions');
    _typingTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _socket.leaveChat(chatId);
    super.onClose();
  }

  void _initializeOnlineStatus() {
    final participants = chat.value?.participants ?? [];
    for (final p in participants) {
      participantOnlineStatus[p.id] = (p.isOnline ?? false).obs;
      participantLastSeen[p.id] = Rx<DateTime?>(p.lastSeen);
    }
    print(
        '[ChatRoom] Initialized status for ${participants.length} participants');
  }

  void _subscribeToSocketEvents() {
    print('[ChatRoom] Subscribing to socket events for chat: $chatId');

    _socket.joinChat(chatId);
    _socket.subscribeChatRoom(chatId);

    // New message
    _subscriptions.add(_socket.onReceiveMessage.listen((msg) {
      if (msg.chatId == chatId) {
        print(
            '[ChatRoom] ✅ Received message via socket: ${msg.id}, content: ${msg.content}');
        _addOrUpdateMessage(msg);

        // Mark as delivered if not from me
        if (msg.senderId != currentUserId) {
          _socket.markMessageDelivered(chatId, msg.id, msg.senderId);
        }
      }
    }));

    // Message status updates
    _subscriptions.add(_socket.onMessageStatus.listen((data) {
      final msgId = data['messageId']?.toString();
      final status = data['status']?.toString();
      if (msgId != null && status != null) {
        print('[ChatRoom] 📨 Status update: $msgId -> $status');
        messageStatuses[msgId] = status;

        // Update message in list
        final index = messages.indexWhere((m) => m.id == msgId);
        if (index != -1) {
          final old = messages[index];
          messages[index] = MessageModel(
            id: old.id,
            chatId: old.chatId,
            content: old.content,
            type: old.type,
            senderId: old.senderId,
            senderName: old.senderName,
            createdAt: old.createdAt,
            status: status,
            replyToId: old.replyToId,
            replyToContent: old.replyToContent,
            replyToSender: old.replyToSender,
            fileUrl: old.fileUrl,
            fileName: old.fileName,
            fileSize: old.fileSize,
            fileType: old.fileType,
            isDeleted: old.isDeleted,
            isEdited: old.isEdited,
            editedAt: old.editedAt,
            originalContent: old.originalContent,
            readReceipts: old.readReceipts,
          );
          messages.refresh();
        }
      }
    }));

    // Typing indicators
    _subscriptions.add(_socket.onUserTyping.listen((userName) {
      if (userName != StorageService.userName) {
        typingUser.value = userName;
      }
    }));

    _subscriptions.add(_socket.onUserStopTyping.listen((_) {
      typingUser.value = '';
    }));

    // Pinned message
    _subscriptions.add(_socket.onMessagePinned.listen((data) {
      if (data['chatId'] == chatId) {
        getPinnedMessage();
      }
    }));

    _subscriptions.add(_socket.onMessageUnpinned.listen((msgId) {
      if (pinnedMessage.value?.messageId == msgId) {
        pinnedMessage.value = null;
      }
    }));

    // Message edited
    _subscriptions.add(_socket.onMessageEdited.listen((data) {
      if (data['chatId'] == chatId) {
        final msgId = data['messageId']?.toString();
        final newContent = data['newContent']?.toString();
        if (msgId != null && newContent != null) {
          print('[ChatRoom] ✏️ Message edited: $msgId');
          final index = messages.indexWhere((m) => m.id == msgId);
          if (index != -1) {
            final old = messages[index];
            messages[index] = MessageModel(
              id: old.id,
              chatId: old.chatId,
              content: newContent,
              type: old.type,
              senderId: old.senderId,
              senderName: old.senderName,
              createdAt: old.createdAt,
              status: old.status,
              replyToId: old.replyToId,
              replyToContent: old.replyToContent,
              replyToSender: old.replyToSender,
              fileUrl: old.fileUrl,
              fileName: old.fileName,
              fileSize: old.fileSize,
              fileType: old.fileType,
              isDeleted: old.isDeleted,
              isEdited: true,
              editedAt: DateTime.now(),
              originalContent: old.content,
              readReceipts: old.readReceipts,
            );
            messages.refresh();
          }
        }
      }
    }));

    // Message deleted
    _subscriptions.add(_socket.onMessageDeleted.listen((data) {
      if (data['chatId'] == chatId) {
        final msgId = data['messageId']?.toString();
        final deleteForEveryone = data['deleteForEveryone'] == true;
        if (msgId != null) {
          print(
              '[ChatRoom] 🗑️ Message deleted: $msgId (forEveryone: $deleteForEveryone)');
          if (deleteForEveryone) {
            messages.removeWhere((m) => m.id == msgId);
          } else {
            final index = messages.indexWhere((m) => m.id == msgId);
            if (index != -1 && messages[index].senderId == currentUserId) {
              messages.removeAt(index);
            }
          }
        }
      }
    }));

    // CRITICAL FIX: Reaction added
    _subscriptions.add(_socket.onReactionAdded.listen((data) {
      if (data['chatId'] == chatId) {
        final msgId = data['messageId']?.toString();
        final userId = data['userId']?.toString();
        final userName = data['userName']?.toString();
        final emoji = data['emoji']?.toString();

        if (msgId != null && userId != null && emoji != null) {
          print('[ChatRoom] ➕ Reaction added: $emoji to $msgId by $userId');
          _updateReactionInMap(msgId, emoji, userId, userName, isAdd: true);
        }
      }
    }));

    // CRITICAL FIX: Reaction removed
    _subscriptions.add(_socket.onReactionRemoved.listen((data) {
      if (data['chatId'] == chatId) {
        final msgId = data['messageId']?.toString();
        final userId = data['userId']?.toString();
        final emoji = data['emoji']?.toString();

        if (msgId != null && userId != null && emoji != null) {
          print('[ChatRoom] ➖ Reaction removed: $emoji from $msgId by $userId');
          _updateReactionInMap(msgId, emoji, userId, null, isAdd: false);
        }
      }
    }));

    // User online status
    _subscriptions.add(_socket.onUserOnlineStatus.listen((data) {
      final userId = data['userId']?.toString();
      final isOnline = data['isOnline'] as bool?;
      final lastSeen = data['lastSeen'] != null
          ? DateTime.tryParse(data['lastSeen'].toString())
          : null;

      if (userId != null && userId != currentUserId) {
        print('[ChatRoom] 👤 User status: $userId online=$isOnline');

        // Update reactive values
        if (isOnline != null) {
          if (participantOnlineStatus.containsKey(userId)) {
            participantOnlineStatus[userId]!.value = isOnline;
          } else {
            participantOnlineStatus[userId] = isOnline.obs;
          }
        }

        if (lastSeen != null) {
          if (participantLastSeen.containsKey(userId)) {
            participantLastSeen[userId]!.value = lastSeen;
          } else {
            participantLastSeen[userId] = Rx<DateTime?>(lastSeen);
          }
        }

        participantOnlineStatus.refresh();
        participantLastSeen.refresh();
      }
    }));

    print('[ChatRoom] Socket event subscriptions completed');
  }

  // CRITICAL: Method to update reactions reactively
  void _updateReactionInMap(
      String messageId, String emoji, String userId, String? userName,
      {required bool isAdd}) {
    if (!reactionsByMessage.containsKey(messageId)) {
      reactionsByMessage[messageId] = <ReactionModel>[].obs;
    }

    final reactionsForMsg = reactionsByMessage[messageId]!;
    final existingIndex = reactionsForMsg.indexWhere((r) => r.emoji == emoji);

    if (isAdd) {
      if (existingIndex >= 0) {
        final existing = reactionsForMsg[existingIndex];
        if (!existing.userIds.contains(userId)) {
          final updatedUserIds = [...existing.userIds, userId];
          final updatedUserNames =
              existing.userNames != null && userName != null
                  ? [...existing.userNames!, userName]
                  : existing.userNames;

          reactionsForMsg[existingIndex] = ReactionModel(
            emoji: emoji,
            userIds: updatedUserIds,
            userNames: updatedUserNames,
          );
        }
      } else {
        reactionsForMsg.add(ReactionModel(
          emoji: emoji,
          userIds: [userId],
          userNames: userName != null ? [userName] : null,
        ));
      }
    } else {
      if (existingIndex >= 0) {
        final existing = reactionsForMsg[existingIndex];
        final updatedUserIds =
            existing.userIds.where((id) => id != userId).toList();

        if (updatedUserIds.isEmpty) {
          reactionsForMsg.removeAt(existingIndex);
        } else {
          final updatedUserNames = existing.userNames?.where((name) {
            final index = existing.userIds.indexOf(userId);
            return existing.userNames!.indexOf(name) != index;
          }).toList();

          reactionsForMsg[existingIndex] = ReactionModel(
            emoji: emoji,
            userIds: updatedUserIds,
            userNames: updatedUserNames,
          );
        }
      }
    }

    reactionsForMsg.refresh();
    reactionsByMessage.refresh();
  }

  void _addOrUpdateMessage(MessageModel msg) {
    final index = messages.indexWhere((m) => m.id == msg.id);
    if (index >= 0) {
      messages[index] = msg;
      print('[ChatRoom] Updated existing message: ${msg.id}');
    } else {
      messages.add(msg);
      print(
          '[ChatRoom] Added new message to list. Total messages: ${messages.length}');
    }

    _loadReactionsForMessage(msg.id);
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    error.value = '';

    try {
      await Future.wait([
        getChat(),
        getPinnedMessage(),
        getMessages(),
      ]);
    } catch (e) {
      error.value = e.toString();
      print('[ChatRoom] Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getChat() async {
    try {
      final result = await _repo.getChat(chatId);
      chat.value = result;
      _initializeOnlineStatus();
      print('[ChatRoom] Loaded chat: $chatId');
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> getMessages() async {
    try {
      final result = await _repo.getMessages(chatId);
      messages.assignAll(result);
      print('[ChatRoom] Loaded ${result.length} messages');

      if (result.isNotEmpty) {
        final messageIds = result
            .where((m) => m.senderId != currentUserId)
            .map((m) => m.id)
            .toList();
        if (messageIds.isNotEmpty) {
          markMessagesRead(messageIds);
        }
      }

      await _loadReactionsForAllMessages();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> _loadReactionsForAllMessages() async {
    for (final msg in messages) {
      await _loadReactionsForMessage(msg.id);
    }
  }

  Future<void> _loadReactionsForMessage(String messageId) async {
    try {
      final reactions = await _repo.getReactions(chatId, messageId);

      if (reactions.isNotEmpty) {
        // Convert from Map to ReactionModel
        final Map<String, ReactionModel> aggregated = {};
        for (final r in reactions) {
          final emoji = r['emoji']?.toString() ?? '';
          final userId = r['userId']?.toString();
          final userName = r['userName']?.toString();

          if (emoji.isNotEmpty && userId != null) {
            if (aggregated.containsKey(emoji)) {
              final existing = aggregated[emoji]!;
              aggregated[emoji] = ReactionModel(
                emoji: emoji,
                userIds: [...existing.userIds, userId],
                userNames: existing.userNames != null && userName != null
                    ? [...existing.userNames!, userName]
                    : existing.userNames,
              );
            } else {
              aggregated[emoji] = ReactionModel(
                emoji: emoji,
                userIds: [userId],
                userNames: userName != null ? [userName] : null,
              );
            }
          }
        }

        reactionsByMessage[messageId] = aggregated.values.toList().obs;
      } else {
        reactionsByMessage[messageId] = <ReactionModel>[].obs;
      }
    } catch (e) {
      print('[ChatRoom] Error loading reactions for $messageId: $e');
      reactionsByMessage[messageId] = <ReactionModel>[].obs;
    }
  }

  Future<void> getPinnedMessage() async {
    try {
      final result = await _repo.getPinnedMessage(chatId);
      pinnedMessage.value = result;
    } catch (e) {
      // Ignore
    }
  }

  Future<void> sendText(String content, {String? replyToId}) async {
    if (content.trim().isEmpty) return;

    try {
      final result = await _repo.sendMessage(
        chatId,
        content: content,
        type: 'text',
        replyToId: replyToId ?? replyingToMessage.value?.id,
      );

      _addOrUpdateMessage(result);
      replyingToMessage.value = null;

      _socket.sendMessage(
        chatId,
        content,
        messageId: result.id,
        replyToId: replyToId ?? replyingToMessage.value?.id,
        replyToContent: replyingToMessage.value?.content,
        replyToSender: replyingToMessage.value?.senderName,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    }
  }

  Future<void> sendFile({
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String fileType,
    required String type,
    String? replyToId,
  }) async {
    try {
      final result = await _repo.sendMessage(
        chatId,
        content: fileName,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        replyToId: replyToId ?? replyingToMessage.value?.id,
      );

      _addOrUpdateMessage(result);
      replyingToMessage.value = null;

      _socket.sendMessage(chatId, fileName, messageId: result.id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send file');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _repo.editMessage(chatId, messageId, newContent);

      final index = messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        final old = messages[index];
        messages[index] = MessageModel(
          id: old.id,
          chatId: old.chatId,
          content: newContent,
          type: old.type,
          senderId: old.senderId,
          senderName: old.senderName,
          createdAt: old.createdAt,
          status: old.status,
          replyToId: old.replyToId,
          replyToContent: old.replyToContent,
          replyToSender: old.replyToSender,
          fileUrl: old.fileUrl,
          fileName: old.fileName,
          fileSize: old.fileSize,
          fileType: old.fileType,
          isDeleted: old.isDeleted,
          isEdited: true,
          editedAt: DateTime.now(),
          originalContent: old.content,
          readReceipts: old.readReceipts,
        );
        messages.refresh();
      }

      _socket.editMessage(
          chatId,
          messageId,
          newContent,
          DateTime.now().toIso8601String(),
          messages.firstWhere((m) => m.id == messageId).content);
    } catch (e) {
      Get.snackbar('Error', 'Failed to edit message');
    }
  }

  Future<void> deleteMessage(String messageId,
      {bool deleteForEveryone = false}) async {
    try {
      await _repo.deleteMessage(chatId, messageId,
          deleteForEveryone: deleteForEveryone);

      if (deleteForEveryone) {
        messages.removeWhere((m) => m.id == messageId);
      } else {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index >= 0 && messages[index].senderId == currentUserId) {
          messages.removeAt(index);
        }
      }

      _socket.deleteMessage(chatId, messageId, deleteForEveryone);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message');
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final reactions = reactionsByMessage[messageId] ?? <ReactionModel>[].obs;
      final existingReaction =
          reactions.firstWhereOrNull((r) => r.emoji == emoji);
      final hasReacted =
          existingReaction?.userIds.contains(currentUserId) ?? false;

      if (hasReacted) {
        await _repo.removeReaction(chatId, messageId, emoji);
        _socket.removeReaction(chatId, messageId, emoji);
        _updateReactionInMap(messageId, emoji, currentUserId, null,
            isAdd: false);
      } else {
        await _repo.addReaction(chatId, messageId, emoji);
        _socket.addReaction(chatId, messageId, emoji);
        _updateReactionInMap(messageId, emoji, currentUserId, currentUserName,
            isAdd: true);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update reaction');
    }
  }

  Future<void> pinMessage(String messageId, String duration) async {
    try {
      await _repo.pinMessage(chatId, messageId, duration);

      final msg = messages.firstWhere((m) => m.id == messageId);
      final expiresAt = _calculateExpiry(duration);

      _socket.pinMessage(
          chatId,
          messageId,
          duration,
          expiresAt.toIso8601String(),
          msg.content,
          msg.senderName ?? msg.senderId);

      await getPinnedMessage();
    } catch (e) {
      Get.snackbar('Error', 'Failed to pin message');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    try {
      await _repo.unpinMessage(chatId, messageId);
      _socket.unpinMessage(chatId, messageId);
      pinnedMessage.value = null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to unpin message');
    }
  }

  DateTime _calculateExpiry(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case '24h':
        return now.add(const Duration(hours: 24));
      case '7d':
        return now.add(const Duration(days: 7));
      case '30d':
        return now.add(const Duration(days: 30));
      default:
        return now.add(const Duration(hours: 24));
    }
  }

  void markMessagesRead(List<String> messageIds) {
    if (messageIds.isEmpty) return;

    _repo.markMessagesRead(chatId, messageIds).then((_) {
      if (chat.value?.isGroup == true) {
        _socket.markGroupMessagesSeen(chatId, messageIds);
      } else {
        for (final msgId in messageIds) {
          final msg = messages.firstWhereOrNull((m) => m.id == msgId);
          if (msg != null) {
            _socket.markMessageSeen(chatId, msgId, msg.senderId);
          }
        }
      }
    }).catchError((e) {
      print('[ChatRoom] markMessagesRead error: $e');
    });
  }

  void sendTyping() {
    _socket.sendTyping(chatId);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _socket.sendStopTyping(chatId);
    });
  }

  void stopTyping() {
    _typingTimer?.cancel();
    _socket.sendStopTyping(chatId);
  }

  void openGroupInfo() {
    print('[ChatRoom] Open group info');
  }

  void setReplyMessage(MessageModel message) {
    replyingToMessage.value = message;
  }

  void cancelReply() {
    replyingToMessage.value = null;
  }

  void copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    Get.snackbar('Copied', 'Message copied to clipboard');
  }

  void forwardMessage(MessageModel message) {
    print('[ChatRoom] Forward message: ${message.id}');
    Get.snackbar('Forward', 'Forward functionality coming soon');
  }
}

// import 'dart:async';

// import 'package:get/get.dart';

// import '../../core/network/api_exceptions.dart';
// import '../../core/routes/app_routes.dart';
// import '../../core/utils/error_display.dart';
// import '../../data/models/chat_model.dart';
// import '../../data/models/message_model.dart';
// import '../../data/models/pinned_message_model.dart';
// import '../../data/models/reaction_model.dart';
// import '../../data/models/user_model.dart';
// import '../../data/repositories/chat_repository.dart';
// import '../../data/repositories/message_reactions_repository.dart';
// import '../../services/socket_service.dart';
// import '../../services/storage_service.dart';
// import '../chat_list/chat_list_controller.dart';

// class ChatRoomController extends GetxController {
//   final ChatRepository _chatRepo = ChatRepository();
//   final MessageReactionsRepository _reactionsRepo =
//       MessageReactionsRepository();
//   final SocketService _socket = Get.find<SocketService>();

//   final Rx<ChatModel?> chat = Rx<ChatModel?>(null);
//   final RxList<MessageModel> messages = <MessageModel>[].obs;
//   final RxBool isLoading = true.obs;
//   final RxBool sending = false.obs;
//   final RxString error = ''.obs;
//   final Rx<PinnedMessageModel?> pinnedMessage = Rx<PinnedMessageModel?>(null);
//   final RxString typingUser = ''.obs;

//   // CRITICAL FIX: Use individual Rx wrappers for each message's reactions
//   // This ensures GetX tracks changes at the message level
//   final RxMap<String, RxList<ReactionModel>> reactionsByMessage =
//       <String, RxList<ReactionModel>>{}.obs;

//   // Track online status of participants
//   final RxMap<String, bool> participantOnlineStatus = <String, bool>{}.obs;
//   final RxMap<String, DateTime?> participantLastSeen =
//       <String, DateTime?>{}.obs;

//   // CRITICAL FIX: Add a reactive counter to force UI rebuilds
//   final RxInt _messageUpdateTrigger = 0.obs;
//   RxInt get messageUpdateTrigger => _messageUpdateTrigger;

//   String get chatId => chat.value?.id ?? _chatIdArg;
//   String _chatIdArg = '';
//   String get currentUserId => StorageService.userId ?? '';
//   String get currentUserName => StorageService.userName ?? '';

//   StreamSubscription? _receiveSub;
//   StreamSubscription? _typingSub;
//   StreamSubscription? _stopTypingSub;
//   StreamSubscription? _editedSub;
//   StreamSubscription? _deletedSub;
//   StreamSubscription? _pinnedSub;
//   StreamSubscription? _unpinnedSub;
//   StreamSubscription? _statusSub;
//   StreamSubscription? _reactionAddedSub;
//   StreamSubscription? _reactionRemovedSub;
//   StreamSubscription? _onlineStatusSub;

//   @override
//   void onInit() {
//     super.onInit();
//     final args = Get.arguments as Map<String, dynamic>?;
//     if (args != null) {
//       chat.value = args['chat'] as ChatModel?;
//       final id = args['chatId'] as String? ?? chat.value?.id ?? '';
//       _chatIdArg = id;
//       if (id.isNotEmpty) {
//         _initializeParticipantStatus();
//         _loadChat(id);
//         _loadMessages(id);
//         _loadPinned(id);
//         _socket.joinChat(id);
//         _socket.subscribeChatRoom(id);
//         _subscribeSocket(id);
//       }
//     }
//   }

//   void _initializeParticipantStatus() {
//     final chatValue = chat.value;
//     if (chatValue?.participants != null) {
//       for (final participant in chatValue!.participants!) {
//         participantOnlineStatus[participant.id] = participant.isOnline ?? false;
//         participantLastSeen[participant.id] = participant.lastSeen;
//       }
//       print(
//           '[ChatRoom] Initialized status for ${chatValue.participants!.length} participants');
//     }
//   }

//   void _subscribeSocket(String cid) {
//     print('[ChatRoom] Subscribing to socket events for chat: $cid');

//     _receiveSub = _socket.onReceiveMessage.listen((msg) {
//       if (msg.chatId == cid) {
//         print(
//             '[ChatRoom] ✅ Received message via socket: ${msg.id}, content: ${msg.content}');
//         final exists = messages.indexWhere((m) => m.id == msg.id) != -1;
//         if (!exists) {
//           messages.add(msg);
//           print(
//               '[ChatRoom] Added new message to list. Total messages: ${messages.length}');
//           loadReactionsForMessage(msg.id);
//         } else {
//           print('[ChatRoom] Message already exists, skipping');
//         }
//       }
//     });

//     _typingSub = _socket.onUserTyping.listen((name) {
//       print('[ChatRoom] ✅ User typing: $name');
//       typingUser.value = name;
//     });

//     _stopTypingSub = _socket.onUserStopTyping.listen((_) {
//       print('[ChatRoom] ✅ User stopped typing');
//       typingUser.value = '';
//     });

//     _editedSub = _socket.onMessageEdited.listen((data) {
//       print('[ChatRoom] ✅ Message edited via socket: ${data['messageId']}');
//       final mid = data['messageId']?.toString();
//       final newContent = data['newContent']?.toString();
//       if (mid != null && newContent != null) {
//         _updateMessageInList(
//             mid,
//             (msg) => MessageModel(
//                   id: msg.id,
//                   chatId: msg.chatId,
//                   content: newContent,
//                   type: msg.type,
//                   senderId: msg.senderId,
//                   senderName: msg.senderName,
//                   createdAt: msg.createdAt,
//                   status: msg.status,
//                   isEdited: true,
//                   replyToId: msg.replyToId,
//                   replyToContent: msg.replyToContent,
//                   replyToSender: msg.replyToSender,
//                   fileUrl: msg.fileUrl,
//                   fileName: msg.fileName,
//                   fileSize: msg.fileSize,
//                   fileType: msg.fileType,
//                   isDeleted: msg.isDeleted,
//                   editedAt: DateTime.now(),
//                   originalContent: msg.originalContent,
//                   readReceipts: msg.readReceipts,
//                 ));
//         print('[ChatRoom] Updated message content');
//       }
//     });

//     _deletedSub = _socket.onMessageDeleted.listen((data) {
//       print('[ChatRoom] ✅ Message deleted via socket: ${data['messageId']}');
//       final mid = data['messageId']?.toString();
//       if (mid != null) {
//         messages.removeWhere((m) => m.id == mid);
//         reactionsByMessage.remove(mid);
//         _forceUIUpdate();
//         print('[ChatRoom] Removed message from list');
//       }
//     });

//     _pinnedSub = _socket.onMessagePinned.listen((data) {
//       print('[ChatRoom] ✅ Message pinned via socket: ${data['messageId']}');
//       if (data['chatId']?.toString() == cid) {
//         pinnedMessage.value = PinnedMessageModel(
//           messageId: data['messageId']?.toString() ?? '',
//           content: data['messageContent']?.toString(),
//           pinnedBy: data['pinnedBy']?.toString(),
//           duration: data['duration']?.toString(),
//           expiresAt: data['expiresAt'] != null
//               ? DateTime.tryParse(data['expiresAt'].toString())
//               : null,
//         );
//       }
//     });

//     _unpinnedSub = _socket.onMessageUnpinned.listen((mid) {
//       print('[ChatRoom] ✅ Message unpinned via socket: $mid');
//       if (pinnedMessage.value?.messageId == mid) {
//         pinnedMessage.value = null;
//       }
//     });

//     // CRITICAL FIX: Enhanced message status listener with proper update
//     _statusSub = _socket.onMessageStatus.listen((data) {
//       final chatId = data['chatId']?.toString();
//       final messageId = data['messageId']?.toString();
//       final status = data['status']?.toString();

//       print(
//           '[ChatRoom] ✅ Message status update via socket: chatId=$chatId, messageId=$messageId, status=$status');

//       if (chatId == cid && messageId != null && status != null) {
//         _updateMessageInList(
//             messageId,
//             (msg) => MessageModel(
//                   id: msg.id,
//                   chatId: msg.chatId,
//                   content: msg.content,
//                   type: msg.type,
//                   senderId: msg.senderId,
//                   senderName: msg.senderName,
//                   createdAt: msg.createdAt,
//                   status: status, // Update the status
//                   replyToId: msg.replyToId,
//                   replyToContent: msg.replyToContent,
//                   replyToSender: msg.replyToSender,
//                   fileUrl: msg.fileUrl,
//                   fileName: msg.fileName,
//                   fileSize: msg.fileSize,
//                   fileType: msg.fileType,
//                   isDeleted: msg.isDeleted,
//                   isEdited: msg.isEdited,
//                   editedAt: msg.editedAt,
//                   originalContent: msg.originalContent,
//                   readReceipts: msg.readReceipts,
//                 ));
//         print('[ChatRoom] ✅ Updated message status to: $status');
//       }
//     });

//     // CRITICAL FIX: Enhanced reaction listeners with proper reactivity
//     _reactionAddedSub = _socket.onReactionAdded.listen((data) {
//       final socketChatId = data['chatId']?.toString();
//       final mid = data['messageId']?.toString();
//       final emoji = data['emoji']?.toString();
//       final userId = data['userId']?.toString();
//       final userName = data['userName']?.toString();

//       print(
//           '[ChatRoom] ✅ Reaction added via socket: messageId=$mid, emoji=$emoji, userId=$userId, userName=$userName, socketChatId=$socketChatId, currentChatId=$cid');

//       if (socketChatId == cid &&
//           mid != null &&
//           emoji != null &&
//           userId != null) {
//         print('[ChatRoom] Processing reaction add for current chat');

//         // Get or create RxList for this message
//         if (!reactionsByMessage.containsKey(mid)) {
//           reactionsByMessage[mid] = <ReactionModel>[].obs;
//         }

//         final currentReactions = reactionsByMessage[mid]!;
//         final existingIndex =
//             currentReactions.indexWhere((r) => r.emoji == emoji);

//         if (existingIndex >= 0) {
//           // Update existing reaction
//           final existing = currentReactions[existingIndex];
//           if (!existing.userIds.contains(userId)) {
//             final updatedUserIds = [...existing.userIds, userId];
//             final updatedUserNames =
//                 List<String>.from(existing.userNames ?? []);
//             if (userName != null) updatedUserNames.add(userName);

//             currentReactions[existingIndex] = ReactionModel(
//               emoji: emoji,
//               userIds: updatedUserIds,
//               userNames: updatedUserNames,
//             );
//             print('[ChatRoom] Added user to existing reaction: $emoji');
//           }
//         } else {
//           // Add new reaction
//           currentReactions.add(ReactionModel(
//             emoji: emoji,
//             userIds: [userId],
//             userNames: userName != null ? [userName] : null,
//           ));
//           print('[ChatRoom] Created new reaction: $emoji');
//         }

//         // CRITICAL: Trigger reactivity
//         currentReactions.refresh();
//         reactionsByMessage.refresh();
//         _forceUIUpdate();

//         // Verify with server
//         Future.delayed(const Duration(milliseconds: 300), () {
//           loadReactionsForMessage(mid);
//         });
//       } else {
//         print('[ChatRoom] Skipping reaction - chatId mismatch or missing data');
//       }
//     });

//     _reactionRemovedSub = _socket.onReactionRemoved.listen((data) {
//       final socketChatId = data['chatId']?.toString();
//       final mid = data['messageId']?.toString();
//       final emoji = data['emoji']?.toString();
//       final userId = data['userId']?.toString();

//       print(
//           '[ChatRoom] ✅ Reaction removed via socket: messageId=$mid, emoji=$emoji, userId=$userId, socketChatId=$socketChatId');

//       if (socketChatId == cid &&
//           mid != null &&
//           emoji != null &&
//           userId != null) {
//         print('[ChatRoom] Processing reaction removal for current chat');

//         if (reactionsByMessage.containsKey(mid)) {
//           final currentReactions = reactionsByMessage[mid]!;
//           final existingIndex =
//               currentReactions.indexWhere((r) => r.emoji == emoji);

//           if (existingIndex >= 0) {
//             final existing = currentReactions[existingIndex];
//             final updatedUserIds =
//                 existing.userIds.where((id) => id != userId).toList();

//             if (updatedUserIds.isEmpty) {
//               currentReactions.removeAt(existingIndex);
//               print('[ChatRoom] Removed reaction completely: $emoji');
//             } else {
//               final updatedUserNames = existing.userNames
//                   ?.where((name) =>
//                       existing.userIds.indexOf(name) !=
//                       existing.userIds.indexOf(userId))
//                   .toList()
//                   .cast<String>();

//               currentReactions[existingIndex] = ReactionModel(
//                 emoji: emoji,
//                 userIds: updatedUserIds,
//                 userNames: updatedUserNames,
//               );
//               print('[ChatRoom] Removed user from reaction: $emoji');
//             }

//             // CRITICAL: Trigger reactivity
//             currentReactions.refresh();
//             reactionsByMessage.refresh();
//             _forceUIUpdate();
//           }
//         }

//         // Verify with server
//         Future.delayed(const Duration(milliseconds: 300), () {
//           loadReactionsForMessage(mid);
//         });
//       }
//     });

//     _onlineStatusSub = _socket.onUserOnlineStatus.listen((data) {
//       final userId = data['userId']?.toString();
//       final isOnline = data['isOnline'] as bool?;
//       final lastSeen = data['lastSeen']?.toString();

//       print(
//           '[ChatRoom] ✅ User online status update: userId=$userId, isOnline=$isOnline, lastSeen=$lastSeen');

//       if (userId != null && userId != currentUserId) {
//         if (isOnline != null) {
//           participantOnlineStatus[userId] = isOnline;
//         }
//         if (lastSeen != null) {
//           participantLastSeen[userId] = DateTime.tryParse(lastSeen);
//         }

//         participantOnlineStatus.refresh();
//         participantLastSeen.refresh();

//         final chatValue = chat.value;
//         if (chatValue?.participants != null) {
//           final participantIndex =
//               chatValue!.participants!.indexWhere((p) => p.id == userId);
//           if (participantIndex >= 0) {
//             final updatedParticipants =
//                 List<UserModel>.from(chatValue.participants!);
//             final oldParticipant = updatedParticipants[participantIndex];

//             updatedParticipants[participantIndex] = UserModel(
//               id: oldParticipant.id,
//               name: oldParticipant.name,
//               email: oldParticipant.email,
//               avatar: oldParticipant.avatar,
//               phone: oldParticipant.phone,
//               bio: oldParticipant.bio,
//               status: oldParticipant.status,
//               isOnline: isOnline ?? oldParticipant.isOnline,
//               lastSeen: lastSeen != null
//                   ? DateTime.tryParse(lastSeen)
//                   : oldParticipant.lastSeen,
//             );

//             chat.value = ChatModel(
//               id: chatValue.id,
//               name: chatValue.name,
//               description: chatValue.description,
//               avatar: chatValue.avatar,
//               type: chatValue.type,
//               groupId: chatValue.groupId,
//               participants: updatedParticipants,
//               participantIds: chatValue.participantIds,
//               lastMessage: chatValue.lastMessage,
//               updatedAt: chatValue.updatedAt,
//               unreadCount: chatValue.unreadCount,
//               pinnedMessageId: chatValue.pinnedMessageId,
//             );

//             print('[ChatRoom] Updated chat participant status in chat model');
//           }
//         }

//         print(
//             '[ChatRoom] Participant status updated: userId=$userId, online=${participantOnlineStatus[userId]}');
//       }
//     });

//     print('[ChatRoom] Socket event subscriptions completed');
//   }

//   // CRITICAL FIX: Helper method to update message in list properly
//   void _updateMessageInList(
//       String messageId, MessageModel Function(MessageModel) updateFn) {
//     final idx = messages.indexWhere((m) => m.id == messageId);
//     if (idx >= 0) {
//       messages[idx] = updateFn(messages[idx]);
//       messages.refresh(); // Force list refresh
//       _forceUIUpdate(); // Force UI rebuild
//       print('[ChatRoom] ✅ Message updated at index $idx');
//     } else {
//       print('[ChatRoom] ⚠️ Message not found in list: $messageId');
//     }
//   }

//   // CRITICAL FIX: Force UI update by incrementing trigger
//   void _forceUIUpdate() {
//     _messageUpdateTrigger.value++;
//   }

//   Future<void> _loadChat(String id) async {
//     try {
//       chat.value = await _chatRepo.getChat(id);
//       print('[ChatRoom] getChat success: chatId=$id, name=${chat.value?.name}');
//       _initializeParticipantStatus();
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> _loadMessages(String id) async {
//     isLoading.value = true;
//     error.value = '';
//     try {
//       final list = await _chatRepo.getMessages(id);
//       print('[ChatRoom] getMessages success: chatId=$id, count=${list.length}');

//       final enriched = list.map((m) {
//         if (m.senderId != currentUserId || (m.readReceipts == null)) {
//           return m;
//         }
//         final others =
//             m.readReceipts!.where((r) => r.userId != currentUserId).toList();
//         final status = others.isNotEmpty ? 'seen' : 'sent';
//         return MessageModel(
//           id: m.id,
//           chatId: m.chatId,
//           content: m.content,
//           type: m.type,
//           senderId: m.senderId,
//           senderName: m.senderName,
//           createdAt: m.createdAt,
//           status: status,
//           replyToId: m.replyToId,
//           replyToContent: m.replyToContent,
//           replyToSender: m.replyToSender,
//           fileUrl: m.fileUrl,
//           fileName: m.fileName,
//           fileSize: m.fileSize,
//           fileType: m.fileType,
//           isDeleted: m.isDeleted,
//           isEdited: m.isEdited,
//           editedAt: m.editedAt,
//           originalContent: m.originalContent,
//           readReceipts: m.readReceipts,
//         );
//       }).toList();

//       messages.assignAll(enriched);
//       _forceUIUpdate();

//       _loadAllReactionsInBackground(enriched);

//       final toMark = list
//           .where((m) => m.senderId != currentUserId)
//           .map((m) => m.id)
//           .toList();
//       if (toMark.isNotEmpty) {
//         await _chatRepo.markMessagesRead(id, toMark);
//         if (chat.value?.isGroup == true) {
//           _socket.markGroupMessagesSeen(id, toMark);
//         } else {
//           for (final m in list.where((m) => m.senderId != currentUserId)) {
//             _socket.markMessageSeen(id, m.id, m.senderId);
//           }
//         }
//       }
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

//   void _loadAllReactionsInBackground(List<MessageModel> messages) {
//     if (messages.isEmpty) return;

//     Future.microtask(() async {
//       try {
//         const batchSize = 10;
//         for (var i = 0; i < messages.length; i += batchSize) {
//           final batch = messages.skip(i).take(batchSize).toList();
//           await Future.wait(
//             batch.map((msg) => loadReactionsForMessage(msg.id)),
//             eagerError: false,
//           );
//           if (i + batchSize < messages.length) {
//             await Future.delayed(const Duration(milliseconds: 50));
//           }
//         }
//         print('[ChatRoom] Loaded reactions for ${messages.length} messages');
//       } catch (e) {
//         print('[ChatRoom] Error loading reactions in background: $e');
//       }
//     });
//   }

//   Future<void> loadReactionsForMessage(String messageId) async {
//     try {
//       final list = await _reactionsRepo.getReactions(chatId, messageId);

//       // CRITICAL: Create or update RxList
//       if (!reactionsByMessage.containsKey(messageId)) {
//         reactionsByMessage[messageId] = <ReactionModel>[].obs;
//       }

//       reactionsByMessage[messageId]!.assignAll(list);
//       reactionsByMessage[messageId]!.refresh();
//       reactionsByMessage.refresh();
//       _forceUIUpdate();

//       print(
//           '[ChatRoom] ✅ Loaded ${list.length} reactions for message $messageId');
//     } catch (e) {
//       print('[ChatRoom] loadReactionsForMessage error for $messageId: $e');
//       if (!reactionsByMessage.containsKey(messageId)) {
//         reactionsByMessage[messageId] = <ReactionModel>[].obs;
//       }
//     }
//   }

//   Future<void> _loadPinned(String id) async {
//     try {
//       pinnedMessage.value = await _chatRepo.getPinnedMessage(id);
//       print(
//           '[ChatRoom] getPinnedMessage success: chatId=$id, pinned=${pinnedMessage.value?.messageId}');
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> sendText(String content,
//       {String? replyToId,
//       String? replyToContent,
//       String? replyToSender}) async {
//     if (chatId.isEmpty || content.trim().isEmpty) return;
//     sending.value = true;
//     error.value = '';
//     try {
//       final msg = await _chatRepo.sendMessage(chatId,
//           content: content.trim(), replyToId: replyToId);
//       print(
//           '[ChatRoom] sendMessage success: messageId=${msg.id}, chatId=$chatId');

//       _socket.sendMessage(chatId, content.trim(),
//           messageId: msg.id,
//           replyToId: replyToId,
//           replyToContent: replyToContent,
//           replyToSender: replyToSender);
//     } on ApiException catch (e) {
//       error.value = e.message;
//       showApiError(e);
//     } catch (e) {
//       error.value = e.toString();
//       showApiError(e);
//     } finally {
//       sending.value = false;
//     }
//   }

//   void sendTyping() => _socket.sendTyping(chatId);
//   void stopTyping() => _socket.sendStopTyping(chatId);

//   Future<void> editMessage(String messageId, String newContent) async {
//     try {
//       await _chatRepo.editMessage(chatId, messageId, newContent);
//       print('[ChatRoom] editMessage success: messageId=$messageId');
//       _socket.editMessage(
//           chatId, messageId, newContent, DateTime.now().toIso8601String(), '');
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> deleteMessage(String messageId,
//       {bool deleteForEveryone = false}) async {
//     try {
//       await _chatRepo.deleteMessage(chatId, messageId,
//           deleteForEveryone: deleteForEveryone);
//       print('[ChatRoom] deleteMessage success: messageId=$messageId');
//       _socket.deleteMessage(chatId, messageId, deleteForEveryone);
//       messages.removeWhere((m) => m.id == messageId);
//       reactionsByMessage.remove(messageId);
//       _forceUIUpdate();
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> pinMessage(String messageId, String duration) async {
//     try {
//       final msg = messages.firstWhereOrNull((m) => m.id == messageId);
//       await _chatRepo.pinMessage(chatId, messageId, duration);
//       print('[ChatRoom] pinMessage success: messageId=$messageId');
//       _socket.pinMessage(chatId, messageId, duration, '', msg?.content ?? '',
//           msg?.senderName ?? '');
//       await _loadPinned(chatId);
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   Future<void> unpinMessage(String messageId) async {
//     try {
//       await _chatRepo.unpinMessage(chatId, messageId);
//       print('[ChatRoom] unpinMessage success: messageId=$messageId');
//       _socket.unpinMessage(chatId, messageId);
//       pinnedMessage.value = null;
//     } catch (e) {
//       showApiError(e);
//     }
//   }

//   void openGroupInfo() {
//     final chatValue = chat.value;
//     if (chatValue == null) return;

//     final groupId =
//         chatValue.groupId ?? (chatValue.isGroup ? chatValue.id : null);
//     if (groupId != null) {
//       Get.toNamed(AppRoutes.groupInfo,
//           arguments: {'groupId': groupId, 'chatId': chatId});
//     } else {
//       print(
//           '[ChatRoom] openGroupInfo: Cannot open - groupId is null and chat is not a group');
//     }
//   }

//   Future<void> toggleReaction(String messageId, String emoji) async {
//     if (!reactionsByMessage.containsKey(messageId)) {
//       reactionsByMessage[messageId] = <ReactionModel>[].obs;
//     }

//     final existing = reactionsByMessage[messageId]!;
//     final myId = currentUserId;

//     final target = existing.firstWhereOrNull((r) => r.emoji == emoji);
//     final hasReacted = target != null && target.userIds.contains(myId);

//     print(
//         '[ChatRoom] toggleReaction: messageId=$messageId, emoji=$emoji, hasReacted=$hasReacted');

//     // Optimistic update
//     _updateReactionOptimistically(messageId, emoji, hasReacted);

//     try {
//       if (hasReacted) {
//         await _reactionsRepo.removeReaction(chatId, messageId, emoji);
//         print(
//             '[ChatRoom] API: Reaction removed: messageId=$messageId, emoji=$emoji');
//         _socket.removeReaction(chatId, messageId, emoji);
//       } else {
//         await _reactionsRepo.addReaction(chatId, messageId, emoji);
//         print(
//             '[ChatRoom] API: Reaction added: messageId=$messageId, emoji=$emoji');
//         _socket.addReaction(chatId, messageId, emoji);
//       }

//       // Refresh from server to ensure consistency
//       _debouncedReactionRefresh(messageId);
//     } catch (e) {
//       print('[ChatRoom] toggleReaction error: $e');
//       showApiError(e);

//       // Revert optimistic update on error
//       _updateReactionOptimistically(messageId, emoji, !hasReacted);
//     }
//   }

//   void _updateReactionOptimistically(
//       String messageId, String emoji, bool isRemoving) {
//     if (!reactionsByMessage.containsKey(messageId)) {
//       reactionsByMessage[messageId] = <ReactionModel>[].obs;
//     }

//     final currentReactions = reactionsByMessage[messageId]!;
//     final myId = currentUserId;
//     final myName = currentUserName;

//     if (isRemoving) {
//       final index = currentReactions.indexWhere((r) => r.emoji == emoji);
//       if (index >= 0) {
//         final reaction = currentReactions[index];
//         final updatedUserIds =
//             reaction.userIds.where((id) => id != myId).toList();

//         if (updatedUserIds.isEmpty) {
//           currentReactions.removeAt(index);
//         } else {
//           currentReactions[index] = ReactionModel(
//             emoji: emoji,
//             userIds: updatedUserIds,
//             userNames: reaction.userNames
//                 ?.where((name) =>
//                     reaction.userIds.indexOf(name) !=
//                     reaction.userIds.indexOf(myId))
//                 .toList()
//                 .cast<String>(),
//           );
//         }
//       }
//     } else {
//       final index = currentReactions.indexWhere((r) => r.emoji == emoji);
//       if (index >= 0) {
//         final reaction = currentReactions[index];
//         if (!reaction.userIds.contains(myId)) {
//           currentReactions[index] = ReactionModel(
//             emoji: emoji,
//             userIds: [...reaction.userIds, myId],
//             userNames: [...List<String>.from(reaction.userNames ?? []), myName],
//           );
//         }
//       } else {
//         currentReactions.add(ReactionModel(
//           emoji: emoji,
//           userIds: [myId],
//           userNames: [myName],
//         ));
//       }
//     }

//     currentReactions.refresh();
//     reactionsByMessage.refresh();
//     _forceUIUpdate();
//     print('[ChatRoom] Optimistic reaction update completed');
//   }

//   Timer? _reactionRefreshTimer;
//   final Map<String, DateTime> _lastRefreshTime = {};

//   void _debouncedReactionRefresh(String messageId) {
//     final lastRefresh = _lastRefreshTime[messageId];
//     final now = DateTime.now();

//     if (lastRefresh != null &&
//         now.difference(lastRefresh).inMilliseconds < 500) {
//       return;
//     }

//     _reactionRefreshTimer?.cancel();
//     _reactionRefreshTimer = Timer(const Duration(milliseconds: 300), () {
//       loadReactionsForMessage(messageId);
//       _lastRefreshTime[messageId] = DateTime.now();
//     });
//   }

//   @override
//   void onClose() {
//     print('[ChatRoom] Closing controller and cleaning up subscriptions');
//     if (chatId.isNotEmpty) _socket.leaveChat(chatId);
//     _receiveSub?.cancel();
//     _typingSub?.cancel();
//     _stopTypingSub?.cancel();
//     _editedSub?.cancel();
//     _deletedSub?.cancel();
//     _pinnedSub?.cancel();
//     _unpinnedSub?.cancel();
//     _statusSub?.cancel();
//     _reactionAddedSub?.cancel();
//     _reactionRemovedSub?.cancel();
//     _onlineStatusSub?.cancel();
//     _reactionRefreshTimer?.cancel();
//     super.onClose();
//   }
// }
