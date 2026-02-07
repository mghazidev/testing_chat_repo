import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/pinned_message_model.dart';

class ChatRemoteDataSource {
  final ApiClient _client = ApiClient();

  Future<List<ChatModel>> getAllChats() async {
    try {
      final res = await _client.get(ApiEndpoints.chats);
      final data = unwrapResponse(res.data);
      if (data is List) {
        return data.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (data is Map && data['chats'] is List) {
        return (data['chats'] as List)
            .map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get chats failed');
    }
  }

  Future<ChatModel> getChat(String chatId) async {
    try {
      final res = await _client.get(ApiEndpoints.chat(chatId));
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return ChatModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get chat failed');
    }
  }

  Future<ChatModel> createDirectChat(String userId) async {
    try {
      final res = await _client.post(ApiEndpoints.chats, data: {'userId': userId});
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return ChatModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Create chat failed');
    }
  }

  Future<ChatModel> createGroup({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    try {
      final res = await _client.post(ApiEndpoints.chats, data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'participantIds': participantIds,
      });
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      return ChatModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Create group failed');
    }
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final res = await _client.get(ApiEndpoints.chatMessages(chatId));
      final data = unwrapResponse(res.data);
      if (data is List) {
        return data.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['chatId'] = chatId;
          return MessageModel.fromJson(m);
        }).toList();
      }
      if (data is Map && data['messages'] is List) {
        return (data['messages'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['chatId'] = chatId;
          return MessageModel.fromJson(m);
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get messages failed');
    }
  }

  Future<MessageModel> sendMessage(
    String chatId, {
    required String content,
    String type = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? replyToId,
  }) async {
    try {
      final body = {
        'content': content,
        'type': type,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (fileType != null) 'fileType': fileType,
        if (replyToId != null) 'replyToId': replyToId,
      };
      final res = await _client.post(ApiEndpoints.chatMessages(chatId), data: body);
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      final m = Map<String, dynamic>.from(data);
      m['chatId'] = chatId;
      return MessageModel.fromJson(m);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Send message failed');
    }
  }

  Future<MessageModel> editMessage(String chatId, String messageId, String content) async {
    try {
      final res = await _client.put(ApiEndpoints.chatMessage(chatId, messageId), data: {'content': content});
      final data = unwrapResponse(res.data);
      if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
      final m = Map<String, dynamic>.from(data);
      m['chatId'] = chatId;
      return MessageModel.fromJson(m);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Edit message failed');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) async {
    try {
      await _client.delete(ApiEndpoints.chatMessage(chatId, messageId), data: {'deleteForEveryone': deleteForEveryone});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Delete message failed');
    }
  }

  Future<void> markMessagesRead(String chatId, List<String> messageIds) async {
    try {
      await _client.post(ApiEndpoints.chatMessagesRead(chatId), data: {'messageIds': messageIds});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Mark read failed');
    }
  }

  Future<PinnedMessageModel?> getPinnedMessage(String chatId) async {
    try {
      final res = await _client.get(ApiEndpoints.chatPin(chatId));
      final data = unwrapResponse(res.data);
      if (data == null) return null;
      if (data is Map<String, dynamic>) return PinnedMessageModel.fromJson(data);
      return null;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get pin failed');
    }
  }

  Future<void> pinMessage(String chatId, String messageId, String duration) async {
    try {
      await _client.post(ApiEndpoints.chatPin(chatId), data: {'messageId': messageId, 'duration': duration});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Pin failed');
    }
  }

  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _client.delete('${ApiEndpoints.chatPin(chatId)}?messageId=$messageId');
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Unpin failed');
    }
  }
}
