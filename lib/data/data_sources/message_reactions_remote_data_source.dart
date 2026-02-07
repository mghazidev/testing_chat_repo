import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../models/reaction_model.dart';

class MessageReactionsRemoteDataSource {
  final ApiClient _client = ApiClient();

  Future<List<ReactionModel>> getReactions(String chatId, String messageId) async {
    try {
      final res = await _client.get(ApiEndpoints.chatMessageReactions(chatId, messageId));
      final data = unwrapResponse(res.data);
      if (data is List) {
        return data.map((e) => ReactionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (data is Map && data['reactions'] is List) {
        return (data['reactions'] as List)
            .map((e) => ReactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Get reactions failed');
    }
  }

  Future<void> addReaction(String chatId, String messageId, String emoji) async {
    try {
      await _client.post(ApiEndpoints.chatMessageReactions(chatId, messageId), data: {'emoji': emoji});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Add reaction failed');
    }
  }

  Future<void> removeReaction(String chatId, String messageId, String emoji) async {
    try {
      await _client.delete('${ApiEndpoints.chatMessageReactions(chatId, messageId)}?emoji=${Uri.encodeComponent(emoji)}');
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'Remove reaction failed');
    }
  }
}
