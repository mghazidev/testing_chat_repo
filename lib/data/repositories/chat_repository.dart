import '../data_sources/chat_remote_data_source.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/pinned_message_model.dart';

class ChatRepository {
  final ChatRemoteDataSource _dataSource = ChatRemoteDataSource();

  Future<List<ChatModel>> getAllChats() => _dataSource.getAllChats();

  Future<ChatModel> getChat(String chatId) => _dataSource.getChat(chatId);

  Future<ChatModel> createDirectChat(String userId) => _dataSource.createDirectChat(userId);

  Future<ChatModel> createGroup({
    required String name,
    String? description,
    required List<String> participantIds,
  }) =>
      _dataSource.createGroup(name: name, description: description, participantIds: participantIds);

  Future<List<MessageModel>> getMessages(String chatId) => _dataSource.getMessages(chatId);

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

  Future<MessageModel> editMessage(String chatId, String messageId, String content) =>
      _dataSource.editMessage(chatId, messageId, content);

  Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) =>
      _dataSource.deleteMessage(chatId, messageId, deleteForEveryone: deleteForEveryone);

  Future<void> markMessagesRead(String chatId, List<String> messageIds) =>
      _dataSource.markMessagesRead(chatId, messageIds);

  Future<PinnedMessageModel?> getPinnedMessage(String chatId) =>
      _dataSource.getPinnedMessage(chatId);

  Future<void> pinMessage(String chatId, String messageId, String duration) =>
      _dataSource.pinMessage(chatId, messageId, duration);

  Future<void> unpinMessage(String chatId, String messageId) =>
      _dataSource.unpinMessage(chatId, messageId);
}
