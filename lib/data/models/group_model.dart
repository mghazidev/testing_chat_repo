import 'user_model.dart';

class GroupMemberModel {
  final String userId;
  final String? name;
  final String? avatar;
  final String role;

  GroupMemberModel({
    required this.userId,
    this.name,
    this.avatar,
    this.role = 'member',
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      // API sends participants as { id, name, avatar, role, ... }
      userId: (json['userId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      role: (json['role'] ?? 'member').toString(),
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final List<GroupMemberModel>? members;
  final String? createdBy;
  final Map<String, dynamic>? settings;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.members,
    this.createdBy,
    this.settings,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? '';
    List<GroupMemberModel>? members;
    final rawMembers =
        json['members'] is List ? json['members'] : json['participants'];
    if (rawMembers is List) {
      members = rawMembers
          .map((e) =>
              GroupMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    String? createdById;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        createdById = json['createdBy']['id']?.toString() ??
            json['createdBy']['_id']?.toString();
      } else {
        createdById = json['createdBy'].toString();
      }
    }

    return GroupModel(
      id: id.toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      avatar: json['avatar']?.toString(),
      members: members,
      createdBy: createdById,
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : null,
    );
  }
}

class GroupSettingsModel {
  final bool? onlyAdminsCanSend;
  final bool? onlyAdminsCanEditInfo;
  final bool? approvalRequired;
  final bool? disappearingMessages;
  final bool? disappearingDuration;
  final bool? sendMediaMessages;
  final bool? sendLinks;

  GroupSettingsModel({
    this.onlyAdminsCanSend,
    this.onlyAdminsCanEditInfo,
    this.approvalRequired,
    this.disappearingMessages,
    this.disappearingDuration,
    this.sendMediaMessages,
    this.sendLinks,
  });

  factory GroupSettingsModel.fromJson(Map<String, dynamic> json) {
    return GroupSettingsModel(
      onlyAdminsCanSend: json['onlyAdminsCanSend'] is bool
          ? json['onlyAdminsCanSend'] as bool
          : (json['whoCanSendMessages']?.toString() == 'admins' ||
              json['whoCanSendMessages']?.toString() == 'admin'),
      onlyAdminsCanEditInfo: json['onlyAdminsCanEditInfo'] is bool
          ? json['onlyAdminsCanEditInfo'] as bool
          : (json['whoCanEditGroupInfo']?.toString() == 'admins' ||
              json['whoCanEditGroupInfo']?.toString() == 'admin'),
      approvalRequired: json['approveNewMembers'] is bool
          ? json['approveNewMembers'] as bool
          : (json['approvalRequired'] is bool
              ? json['approvalRequired'] as bool
              : null),
      disappearingMessages: json['disappearingMessages'] is bool
          ? json['disappearingMessages'] as bool
          : null,
      disappearingDuration: json['disappearingDuration'] is bool
          ? json['disappearingDuration'] as bool
          : null,
      sendMediaMessages: json['sendMediaMessages'] is bool
          ? json['sendMediaMessages'] as bool
          : null,
      sendLinks: json['sendLinks'] is bool ? json['sendLinks'] as bool : null,
    );
  }
}
