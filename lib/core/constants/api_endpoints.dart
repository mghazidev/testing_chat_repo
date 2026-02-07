import 'package:softex_chat_app/core/config/api_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get _base => ApiConfig.apiBase;

  // Auth
  static String get login => '$_base/auth/login';
  static String get logout => '$_base/auth/logout';
  static String get verify => '$_base/auth/verify';

  // Chats
  static String get chats => '$_base/chats';
  static String chat(String id) => '$_base/chats/$id';
  static String chatMessages(String chatId) => '$_base/chats/$chatId/messages';
  static String chatMessage(String chatId, String messageId) =>
      '$_base/chats/$chatId/messages/$messageId';
  static String chatMessageReactions(String chatId, String messageId) =>
      '$_base/chats/$chatId/messages/$messageId/reactions';
  static String chatMessagesRead(String chatId) =>
      '$_base/chats/$chatId/messages/read';
  static String chatPin(String chatId) => '$_base/chats/$chatId/pin';

  // Groups
  static String group(String id) => '$_base/groups/$id';
  static String groupLeave(String id) => '$_base/groups/$id/leave';
  static String groupMembers(String id) => '$_base/groups/$id/members';
  static String groupMember(String groupId, String memberId) =>
      '$_base/groups/$groupId/members/$memberId';
  static String groupSettings(String id) => '$_base/groups/$id/settings';

  // Users
  static String get currentUser => '$_base/users/me';
  static String user(String id) => '$_base/users/$id';
  static String get userSearch => '$_base/users/search';
  static String get userStatus => '$_base/users/status';
}
