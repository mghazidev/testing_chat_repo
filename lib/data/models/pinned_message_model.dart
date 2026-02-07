class PinnedMessageModel {
  final String messageId;
  final String? content;
  final String? pinnedBy;
  final String? duration;
  final DateTime? expiresAt;

  PinnedMessageModel({
    required this.messageId,
    this.content,
    this.pinnedBy,
    this.duration,
    this.expiresAt,
  });

  factory PinnedMessageModel.fromJson(Map<String, dynamic> json) {
    return PinnedMessageModel(
      messageId: (json['messageId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      content: json['content']?.toString(),
      pinnedBy: json['pinnedBy']?.toString(),
      duration: json['duration']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }
}
