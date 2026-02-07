import 'user_model.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String? name;
  final String? description;
  final String? avatar;
  final String? type;
  final String? groupId;
  final List<UserModel>? participants;
  final List<String>? participantIds;
  final MessageModel? lastMessage;
  final DateTime? updatedAt;
  final int? unreadCount;
  final String? pinnedMessageId;

  ChatModel({
    required this.id,
    this.name,
    this.description,
    this.avatar,
    this.type,
    this.groupId,
    this.participants,
    this.participantIds,
    this.lastMessage,
    this.updatedAt,
    this.unreadCount,
    this.pinnedMessageId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? '';
    List<UserModel>? participants;
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    MessageModel? lastMessage;
    if (json['lastMessage'] is Map) {
      lastMessage = MessageModel.fromJson({
        ...Map<String, dynamic>.from(json['lastMessage'] as Map),
        'chatId': id,
      });
    }
    List<String>? participantIds;
    if (json['participantIds'] is List) {
      participantIds =
          (json['participantIds'] as List).map((e) => e.toString()).toList();
    }
    final typeStr = json['type']?.toString();
    final isGroup = json['isGroup'] == true;
    final type = typeStr ?? (isGroup ? 'group' : 'direct');
    final groupIdValue =
        json['groupId']?.toString() ?? (isGroup ? id.toString() : null);
    return ChatModel(
      id: id.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      avatar: json['avatar']?.toString(),
      type: type,
      groupId: groupIdValue,
      participants: participants,
      participantIds: participantIds,
      lastMessage: lastMessage,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      unreadCount:
          json['unreadCount'] is int ? json['unreadCount'] as int : null,
      pinnedMessageId: json['pinnedMessageId']?.toString(),
    );
  }

  bool get isGroup => type == 'group';
}
