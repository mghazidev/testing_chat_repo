class ReactionModel {
  final String emoji;

  final List<String> userIds;
  final List<String>? userNames;

  ReactionModel({
    required this.emoji,
    required this.userIds,
    this.userNames,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    // Backend in logs sends different shapes:
    // 1) { emoji, userId, userName }
    // 2) { emoji, userIdd, userName }
    // 3) { emoji, userId:: ..., userName }
    // 4) Aggregated: { emoji, userIds: [...], userNames: [...] }
    final emoji = (json['emoji'] ?? '').toString();

    List<String> userIds = [];
    List<String>? userNames;
    if (json['userIds'] is List) {
      userIds = (json['userIds'] as List).map((e) => e.toString()).toList();
    }
    if (json['userNames'] is List) {
      userNames = (json['userNames'] as List).map((e) => e.toString()).toList();
    }

    if (userIds.isEmpty) {
      final singleUserId =
          (json['userId'] ?? json['userIdd'] ?? json['userId::'])?.toString();
      if (singleUserId != null && singleUserId.isNotEmpty) {
        userIds = [singleUserId];
      }
      final singleUserName = json['userName']?.toString();
      if (singleUserName != null && singleUserName.isNotEmpty) {
        userNames = [singleUserName];
      }
    }

    return ReactionModel(
      emoji: emoji,
      userIds: userIds,
      userNames: userNames,
    );
  }
}
