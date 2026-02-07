import '../data_sources/message_reactions_remote_data_source.dart';
import '../models/reaction_model.dart';

class MessageReactionsRepository {
  final MessageReactionsRemoteDataSource _dataSource = MessageReactionsRemoteDataSource();

  Future<List<ReactionModel>> getReactions(String chatId, String messageId) =>
      _dataSource.getReactions(chatId, messageId);

  Future<void> addReaction(String chatId, String messageId, String emoji) =>
      _dataSource.addReaction(chatId, messageId, emoji);

  Future<void> removeReaction(String chatId, String messageId, String emoji) =>
      _dataSource.removeReaction(chatId, messageId, emoji);
}
