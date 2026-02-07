class ReadReceiptModel {
  final String userId;
  final String? userName;
  final DateTime? readAt;

  ReadReceiptModel({
    required this.userId,
    this.userName,
    this.readAt,
  });

  factory ReadReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReadReceiptModel(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      userName: json['userName']?.toString(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String content;
  final String type;
  final String senderId;
  final String? senderName;
  final DateTime? createdAt;

  final String? status;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final bool? isDeleted;
  final bool? isEdited;
  final DateTime? editedAt;
  final String? originalContent;
  final List<ReadReceiptModel>? readReceipts;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.content,
    this.type = 'text',
    required this.senderId,
    this.senderName,
    this.createdAt,
    this.status,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.isDeleted,
    this.isEdited,
    this.editedAt,
    this.originalContent,
    this.readReceipts,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? '';
    final replyTo = json['replyTo'];
    String? replyToId, replyToContent, replyToSender;
    if (replyTo is Map) {
      replyToId = replyTo['_id']?.toString() ?? replyTo['id']?.toString();
      replyToContent = replyTo['content']?.toString();
      replyToSender =
          replyTo['sender']?.toString() ?? replyTo['senderName']?.toString();
    }

    List<ReadReceiptModel>? readReceipts;
    if (json['readReceipts'] is List) {
      readReceipts = (json['readReceipts'] as List)
          .map((e) =>
              ReadReceiptModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return MessageModel(
      id: id.toString(),
      chatId: (json['chatId'] ?? json['chat'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      senderId: (json['senderId'] ?? json['sender'] ?? json['senderId'] ?? '')
          .toString(),
      senderName: json['senderName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status']?.toString(),
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSender: replyToSender,
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize'] is int ? json['fileSize'] as int : null,
      fileType: json['fileType']?.toString(),
      isDeleted: json['isDeleted'] as bool?,
      isEdited: json['isEdited'] as bool?,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      originalContent: json['originalContent']?.toString(),
      readReceipts: readReceipts,
    );
  }

  Map<String, dynamic> toSendJson({
    String? replyToId,
  }) =>
      {
        'content': content,
        'type': type,
        if (replyToId != null) 'replyToId': replyToId,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (fileType != null) 'fileType': fileType,
      };
}
