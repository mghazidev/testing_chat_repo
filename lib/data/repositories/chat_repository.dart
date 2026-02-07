// import '../data_sources/chat_remote_data_source.dart';
// import '../models/chat_model.dart';
// import '../models/message_model.dart';
// import '../models/pinned_message_model.dart';

// class ChatRepository {
//   final ChatRemoteDataSource _dataSource = ChatRemoteDataSource();

//   Future<List<ChatModel>> getAllChats() => _dataSource.getAllChats();

//   Future<ChatModel> getChat(String chatId) => _dataSource.getChat(chatId);

//   Future<ChatModel> createDirectChat(String userId) =>
//       _dataSource.createDirectChat(userId);

//   Future<ChatModel> createGroup({
//     required String name,
//     String? description,
//     required List<String> participantIds,
//   }) =>
//       _dataSource.createGroup(
//           name: name, description: description, participantIds: participantIds);

//   Future<List<MessageModel>> getMessages(String chatId) =>
//       _dataSource.getMessages(chatId);

//   Future<MessageModel> sendMessage(
//     String chatId, {
//     required String content,
//     String type = 'text',
//     String? fileUrl,
//     String? fileName,
//     int? fileSize,
//     String? fileType,
//     String? replyToId,
//   }) =>
//       _dataSource.sendMessage(
//         chatId,
//         content: content,
//         type: type,
//         fileUrl: fileUrl,
//         fileName: fileName,
//         fileSize: fileSize,
//         fileType: fileType,
//         replyToId: replyToId,
//       );

//   Future<MessageModel> editMessage(
//           String chatId, String messageId, String content) =>
//       _dataSource.editMessage(chatId, messageId, content);

//   Future<void> deleteMessage(String chatId, String messageId,
//           {bool deleteForEveryone = false}) =>
//       _dataSource.deleteMessage(chatId, messageId,
//           deleteForEveryone: deleteForEveryone);

//   Future<void> markMessagesRead(String chatId, List<String> messageIds) =>
//       _dataSource.markMessagesRead(chatId, messageIds);

//   Future<PinnedMessageModel?> getPinnedMessage(String chatId) =>
//       _dataSource.getPinnedMessage(chatId);

//   Future<void> pinMessage(String chatId, String messageId, String duration) =>
//       _dataSource.pinMessage(chatId, messageId, duration);

//   Future<void> unpinMessage(String chatId, String messageId) =>
//       _dataSource.unpinMessage(chatId, messageId);

//   // Reaction methods
//   Future<List<Map<String, dynamic>>> getReactions(
//           String chatId, String messageId) =>
//       _dataSource.getReactions(chatId, messageId);

//   Future<void> addReaction(String chatId, String messageId, String emoji) =>
//       _dataSource.addReaction(chatId, messageId, emoji);

//   Future<void> removeReaction(String chatId, String messageId, String emoji) =>
//       _dataSource.removeReaction(chatId, messageId, emoji);
// }

import '../data_sources/chat_remote_data_source.dart';
import '../data_sources/message_reactions_remote_data_source.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/pinned_message_model.dart';
import '../models/reaction_model.dart';

class ChatRepository {
  final ChatRemoteDataSource _dataSource = ChatRemoteDataSource();
  final MessageReactionsRemoteDataSource _reactionsDataSource =
      MessageReactionsRemoteDataSource();

  Future<List<ChatModel>> getAllChats() => _dataSource.getAllChats();

  Future<ChatModel> getChat(String chatId) => _dataSource.getChat(chatId);

  Future<ChatModel> createDirectChat(String userId) =>
      _dataSource.createDirectChat(userId);

  Future<ChatModel> createGroup({
    required String name,
    String? description,
    required List<String> participantIds,
  }) =>
      _dataSource.createGroup(
          name: name, description: description, participantIds: participantIds);

  Future<List<MessageModel>> getMessages(String chatId) =>
      _dataSource.getMessages(chatId);

  Future<MessageModel> sendMessage(
    String chatId, {
    required String content,
    String type = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? replyToId,
  }) =>
      _dataSource.sendMessage(
        chatId,
        content: content,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        replyToId: replyToId,
      );

  Future<MessageModel> editMessage(
          String chatId, String messageId, String content) =>
      _dataSource.editMessage(chatId, messageId, content);

  Future<void> deleteMessage(String chatId, String messageId,
          {bool deleteForEveryone = false}) =>
      _dataSource.deleteMessage(chatId, messageId,
          deleteForEveryone: deleteForEveryone);

  Future<void> markMessagesRead(String chatId, List<String> messageIds) =>
      _dataSource.markMessagesRead(chatId, messageIds);

  Future<PinnedMessageModel?> getPinnedMessage(String chatId) =>
      _dataSource.getPinnedMessage(chatId);

  Future<void> pinMessage(String chatId, String messageId, String duration) =>
      _dataSource.pinMessage(chatId, messageId, duration);

  Future<void> unpinMessage(String chatId, String messageId) =>
      _dataSource.unpinMessage(chatId, messageId);

  // CRITICAL FIX: Changed return type to List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getReactions(
      String chatId, String messageId) async {
    final reactions =
        await _reactionsDataSource.getReactions(chatId, messageId);
    // Convert ReactionModel to Map for compatibility
    return reactions
        .map((r) => {
              'emoji': r.emoji,
              'userId': r.userIds.isNotEmpty ? r.userIds.first : null,
              'userName': r.userNames != null && r.userNames!.isNotEmpty
                  ? r.userNames!.first
                  : null,
              'userIds': r.userIds,
              'userNames': r.userNames,
            })
        .toList();
  }

  Future<void> addReaction(String chatId, String messageId, String emoji) =>
      _reactionsDataSource.addReaction(chatId, messageId, emoji);

  Future<void> removeReaction(String chatId, String messageId, String emoji) =>
      _reactionsDataSource.removeReaction(chatId, messageId, emoji);
}

// import '../data_sources/chat_remote_data_source.dart';
// import '../models/chat_model.dart';
// import '../models/message_model.dart';
// import '../models/pinned_message_model.dart';

// class ChatRepository {
//   final ChatRemoteDataSource _dataSource = ChatRemoteDataSource();

//   Future<List<ChatModel>> getAllChats() => _dataSource.getAllChats();

//   Future<ChatModel> getChat(String chatId) => _dataSource.getChat(chatId);

//   Future<ChatModel> createDirectChat(String userId) => _dataSource.createDirectChat(userId);

//   Future<ChatModel> createGroup({
//     required String name,
//     String? description,
//     required List<String> participantIds,
//   }) =>
//       _dataSource.createGroup(name: name, description: description, participantIds: participantIds);

//   Future<List<MessageModel>> getMessages(String chatId) => _dataSource.getMessages(chatId);

//   Future<MessageModel> sendMessage(
//     String chatId, {
//     required String content,
//     String type = 'text',
//     String? fileUrl,
//     String? fileName,
//     int? fileSize,
//     String? fileType,
//     String? replyToId,
//   }) =>
//       _dataSource.sendMessage(
//         chatId,
//         content: content,
//         type: type,
//         fileUrl: fileUrl,
//         fileName: fileName,
//         fileSize: fileSize,
//         fileType: fileType,
//         replyToId: replyToId,
//       );

//   Future<MessageModel> editMessage(String chatId, String messageId, String content) =>
//       _dataSource.editMessage(chatId, messageId, content);

//   Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) =>
//       _dataSource.deleteMessage(chatId, messageId, deleteForEveryone: deleteForEveryone);

//   Future<void> markMessagesRead(String chatId, List<String> messageIds) =>
//       _dataSource.markMessagesRead(chatId, messageIds);

//   Future<PinnedMessageModel?> getPinnedMessage(String chatId) =>
//       _dataSource.getPinnedMessage(chatId);

//   Future<void> pinMessage(String chatId, String messageId, String duration) =>
//       _dataSource.pinMessage(chatId, messageId, duration);

//   Future<void> unpinMessage(String chatId, String messageId) =>
//       _dataSource.unpinMessage(chatId, messageId);
// }
