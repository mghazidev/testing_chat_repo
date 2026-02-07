// import 'package:dio/dio.dart';
// import '../../core/config/api_config.dart';
// import '../../services/storage_service.dart';
// import '../models/chat_model.dart';
// import '../models/message_model.dart';
// import '../models/pinned_message_model.dart';

// class ChatRemoteDataSource {
//   final Dio _dio = Dio(BaseOptions(
//     baseUrl: ApiConfig.baseUrl,
//     connectTimeout: const Duration(seconds: 30),
//     receiveTimeout: const Duration(seconds: 30),
//   ));

//   ChatRemoteDataSource() {
//     _dio.interceptors.add(InterceptorsWrapper(
//       onRequest: (options, handler) {
//         final token = StorageService.accessToken;
//         if (token != null) {
//           options.headers['Authorization'] = 'Bearer $token';
//         }
//         return handler.next(options);
//       },
//       onResponse: (response, handler) {
//         print('[API Response] ${response.requestOptions.uri}');
//         print('[API Response] statusCode: ${response.statusCode}');
//         print('[API Response] data: ${response.data}');
//         return handler.next(response);
//       },
//       onError: (error, handler) {
//         print('[API Error] ${error.requestOptions.uri}');
//         print('[API Error] ${error.response?.data}');
//         return handler.next(error);
//       },
//     ));
//   }

//   Future<List<ChatModel>> getAllChats() async {
//     final response = await _dio.get('/api/v1/chats');
//     final data = response.data['data'] as List;
//     return data
//         .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   Future<ChatModel> getChat(String chatId) async {
//     final response = await _dio.get('/api/v1/chats/$chatId');
//     return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
//   }

//   Future<ChatModel> createDirectChat(String userId) async {
//     final response = await _dio.post('/api/v1/chats', data: {'userId': userId});
//     return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
//   }

//   Future<ChatModel> createGroup({
//     required String name,
//     String? description,
//     required List<String> participantIds,
//   }) async {
//     final response = await _dio.post('/api/v1/chats', data: {
//       'name': name,
//       if (description != null) 'description': description,
//       'participantIds': participantIds,
//     });
//     return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
//   }

//   Future<List<MessageModel>> getMessages(String chatId) async {
//     final response = await _dio.get('/api/v1/chats/$chatId/messages');
//     final data = response.data['data'] as List;
//     return data
//         .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   Future<MessageModel> sendMessage(
//     String chatId, {
//     required String content,
//     String type = 'text',
//     String? fileUrl,
//     String? fileName,
//     int? fileSize,
//     String? fileType,
//     String? replyToId,
//   }) async {
//     final response = await _dio.post(
//       '/api/v1/chats/$chatId/messages',
//       data: {
//         'content': content,
//         'type': type,
//         if (fileUrl != null) 'fileUrl': fileUrl,
//         if (fileName != null) 'fileName': fileName,
//         if (fileSize != null) 'fileSize': fileSize,
//         if (fileType != null) 'fileType': fileType,
//         if (replyToId != null) 'replyToId': replyToId,
//       },
//     );
//     return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
//   }

//   Future<MessageModel> editMessage(
//       String chatId, String messageId, String content) async {
//     final response = await _dio.put(
//       '/api/v1/chats/$chatId/messages/$messageId',
//       data: {'content': content},
//     );
//     return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
//   }

//   Future<void> deleteMessage(String chatId, String messageId,
//       {bool deleteForEveryone = false}) async {
//     await _dio.delete(
//       '/api/v1/chats/$chatId/messages/$messageId',
//       data: {'deleteForEveryone': deleteForEveryone},
//     );
//   }

//   Future<void> markMessagesRead(String chatId, List<String> messageIds) async {
//     await _dio.post(
//       '/api/v1/chats/$chatId/messages/read',
//       data: {'messageIds': messageIds},
//     );
//   }

//   Future<PinnedMessageModel?> getPinnedMessage(String chatId) async {
//     try {
//       final response = await _dio.get('/api/v1/chats/$chatId/pin');
//       final data = response.data['data'];
//       if (data == null) return null;
//       return PinnedMessageModel.fromJson(data as Map<String, dynamic>);
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> pinMessage(
//       String chatId, String messageId, String duration) async {
//     await _dio.post(
//       '/api/v1/chats/$chatId/pin',
//       data: {
//         'messageId': messageId,
//         'duration': duration,
//       },
//     );
//   }

//   Future<void> unpinMessage(String chatId, String messageId) async {
//     await _dio.delete('/api/v1/chats/$chatId/pin?messageId=$messageId');
//   }

//   // Reaction methods
//   Future<List<Map<String, dynamic>>> getReactions(
//       String chatId, String messageId) async {
//     final response =
//         await _dio.get('/api/v1/chats/$chatId/messages/$messageId/reactions');
//     final data = response.data['data'] as List;
//     return data.map((e) => e as Map<String, dynamic>).toList();
//   }

//   Future<void> addReaction(
//       String chatId, String messageId, String emoji) async {
//     await _dio.post(
//       '/api/v1/chats/$chatId/messages/$messageId/reactions',
//       data: {'emoji': emoji},
//     );
//   }

//   Future<void> removeReaction(
//       String chatId, String messageId, String emoji) async {
//     await _dio.delete(
//         '/api/v1/chats/$chatId/messages/$messageId/reactions?emoji=$emoji');
//   }
// }

import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../services/storage_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/pinned_message_model.dart';

class ChatRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ChatRemoteDataSource() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('[API Response] ${response.requestOptions.uri}');
        print('[API Response] statusCode: ${response.statusCode}');
        print('[API Response] data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('[API Error] ${error.requestOptions.uri}');
        print('[API Error] ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  Future<List<ChatModel>> getAllChats() async {
    final response = await _dio.get('/api/v1/chats');
    final data = response.data['data'] as List;
    return data
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatModel> getChat(String chatId) async {
    final response = await _dio.get('/api/v1/chats/$chatId');
    return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatModel> createDirectChat(String userId) async {
    final response = await _dio.post('/api/v1/chats', data: {'userId': userId});
    return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatModel> createGroup({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    final response = await _dio.post('/api/v1/chats', data: {
      'name': name,
      if (description != null) 'description': description,
      'participantIds': participantIds,
    });
    return ChatModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final response = await _dio.get('/api/v1/chats/$chatId/messages');
    final data = response.data['data'] as List;
    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final response = await _dio.post(
      '/api/v1/chats/$chatId/messages',
      data: {
        'content': content,
        'type': type,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (fileType != null) 'fileType': fileType,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
    return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MessageModel> editMessage(
      String chatId, String messageId, String content) async {
    final response = await _dio.put(
      '/api/v1/chats/$chatId/messages/$messageId',
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMessage(String chatId, String messageId,
      {bool deleteForEveryone = false}) async {
    await _dio.delete(
      '/api/v1/chats/$chatId/messages/$messageId',
      data: {'deleteForEveryone': deleteForEveryone},
    );
  }

  Future<void> markMessagesRead(String chatId, List<String> messageIds) async {
    await _dio.post(
      '/api/v1/chats/$chatId/messages/read',
      data: {'messageIds': messageIds},
    );
  }

  Future<PinnedMessageModel?> getPinnedMessage(String chatId) async {
    try {
      final response = await _dio.get('/api/v1/chats/$chatId/pin');
      final data = response.data['data'];
      if (data == null) return null;
      return PinnedMessageModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> pinMessage(
      String chatId, String messageId, String duration) async {
    await _dio.post(
      '/api/v1/chats/$chatId/pin',
      data: {
        'messageId': messageId,
        'duration': duration,
      },
    );
  }

  Future<void> unpinMessage(String chatId, String messageId) async {
    await _dio.delete('/api/v1/chats/$chatId/pin?messageId=$messageId');
  }

  // Reaction methods
  Future<List<Map<String, dynamic>>> getReactions(
      String chatId, String messageId) async {
    final response =
        await _dio.get('/api/v1/chats/$chatId/messages/$messageId/reactions');
    final data = response.data['data'] as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    await _dio.post(
      '/api/v1/chats/$chatId/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
  }

  Future<void> removeReaction(
      String chatId, String messageId, String emoji) async {
    await _dio.delete(
        '/api/v1/chats/$chatId/messages/$messageId/reactions?emoji=$emoji');
  }
}

// import 'package:dio/dio.dart';

// import '../../core/constants/api_endpoints.dart';
// import '../../core/network/api_client.dart';
// import '../../core/network/api_exceptions.dart';
// import '../../core/network/api_response.dart';
// import '../models/chat_model.dart';
// import '../models/message_model.dart';
// import '../models/pinned_message_model.dart';

// class ChatRemoteDataSource {
//   final ApiClient _client = ApiClient();

//   Future<List<ChatModel>> getAllChats() async {
//     try {
//       final res = await _client.get(ApiEndpoints.chats);
//       final data = unwrapResponse(res.data);
//       if (data is List) {
//         return data.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
//       }
//       if (data is Map && data['chats'] is List) {
//         return (data['chats'] as List)
//             .map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map)))
//             .toList();
//       }
//       return [];
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get chats failed');
//     }
//   }

//   Future<ChatModel> getChat(String chatId) async {
//     try {
//       final res = await _client.get(ApiEndpoints.chat(chatId));
//       final data = unwrapResponse(res.data);
//       if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
//       return ChatModel.fromJson(data);
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get chat failed');
//     }
//   }

//   Future<ChatModel> createDirectChat(String userId) async {
//     try {
//       final res = await _client.post(ApiEndpoints.chats, data: {'userId': userId});
//       final data = unwrapResponse(res.data);
//       if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
//       return ChatModel.fromJson(data);
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Create chat failed');
//     }
//   }

//   Future<ChatModel> createGroup({
//     required String name,
//     String? description,
//     required List<String> participantIds,
//   }) async {
//     try {
//       final res = await _client.post(ApiEndpoints.chats, data: {
//         'name': name,
//         if (description != null && description.isNotEmpty) 'description': description,
//         'participantIds': participantIds,
//       });
//       final data = unwrapResponse(res.data);
//       if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
//       return ChatModel.fromJson(data);
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Create group failed');
//     }
//   }

//   Future<List<MessageModel>> getMessages(String chatId) async {
//     try {
//       final res = await _client.get(ApiEndpoints.chatMessages(chatId));
//       final data = unwrapResponse(res.data);
//       if (data is List) {
//         return data.map((e) {
//           final m = Map<String, dynamic>.from(e as Map);
//           m['chatId'] = chatId;
//           return MessageModel.fromJson(m);
//         }).toList();
//       }
//       if (data is Map && data['messages'] is List) {
//         return (data['messages'] as List).map((e) {
//           final m = Map<String, dynamic>.from(e as Map);
//           m['chatId'] = chatId;
//           return MessageModel.fromJson(m);
//         }).toList();
//       }
//       return [];
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get messages failed');
//     }
//   }

//   Future<MessageModel> sendMessage(
//     String chatId, {
//     required String content,
//     String type = 'text',
//     String? fileUrl,
//     String? fileName,
//     int? fileSize,
//     String? fileType,
//     String? replyToId,
//   }) async {
//     try {
//       final body = {
//         'content': content,
//         'type': type,
//         if (fileUrl != null) 'fileUrl': fileUrl,
//         if (fileName != null) 'fileName': fileName,
//         if (fileSize != null) 'fileSize': fileSize,
//         if (fileType != null) 'fileType': fileType,
//         if (replyToId != null) 'replyToId': replyToId,
//       };
//       final res = await _client.post(ApiEndpoints.chatMessages(chatId), data: body);
//       final data = unwrapResponse(res.data);
//       if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
//       final m = Map<String, dynamic>.from(data);
//       m['chatId'] = chatId;
//       return MessageModel.fromJson(m);
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Send message failed');
//     }
//   }

//   Future<MessageModel> editMessage(String chatId, String messageId, String content) async {
//     try {
//       final res = await _client.put(ApiEndpoints.chatMessage(chatId, messageId), data: {'content': content});
//       final data = unwrapResponse(res.data);
//       if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
//       final m = Map<String, dynamic>.from(data);
//       m['chatId'] = chatId;
//       return MessageModel.fromJson(m);
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Edit message failed');
//     }
//   }

//   Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) async {
//     try {
//       await _client.delete(ApiEndpoints.chatMessage(chatId, messageId), data: {'deleteForEveryone': deleteForEveryone});
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Delete message failed');
//     }
//   }

//   Future<void> markMessagesRead(String chatId, List<String> messageIds) async {
//     try {
//       await _client.post(ApiEndpoints.chatMessagesRead(chatId), data: {'messageIds': messageIds});
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Mark read failed');
//     }
//   }

//   Future<PinnedMessageModel?> getPinnedMessage(String chatId) async {
//     try {
//       final res = await _client.get(ApiEndpoints.chatPin(chatId));
//       final data = unwrapResponse(res.data);
//       if (data == null) return null;
//       if (data is Map<String, dynamic>) return PinnedMessageModel.fromJson(data);
//       return null;
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get pin failed');
//     }
//   }

//   Future<void> pinMessage(String chatId, String messageId, String duration) async {
//     try {
//       await _client.post(ApiEndpoints.chatPin(chatId), data: {'messageId': messageId, 'duration': duration});
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Pin failed');
//     }
//   }

//   Future<void> unpinMessage(String chatId, String messageId) async {
//     try {
//       await _client.delete('${ApiEndpoints.chatPin(chatId)}?messageId=$messageId');
//     } on DioException catch (e) {
//       throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Unpin failed');
//     }
//   }
// }
