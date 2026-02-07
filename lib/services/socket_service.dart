import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/config/api_config.dart';
import '../data/models/message_model.dart';
import 'storage_service.dart';

class SocketService {
  io.Socket? _socket;
  String? _currentChatId;
  final String _userId = StorageService.userId ?? '';
  final String _userName = StorageService.userName ?? '';

  bool get isConnected => _socket?.connected ?? false;

  final StreamController<MessageModel> _receiveMessageController =
      StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get onReceiveMessage => _receiveMessageController.stream;

  final StreamController<Map<String, dynamic>> _messageStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageStatus =>
      _messageStatusController.stream;

  final StreamController<String> _userTypingController =
      StreamController<String>.broadcast();
  Stream<String> get onUserTyping => _userTypingController.stream;

  final StreamController<void> _userStopTypingController =
      StreamController<void>.broadcast();
  Stream<void> get onUserStopTyping => _userStopTypingController.stream;

  final StreamController<Map<String, dynamic>> _messagePinnedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessagePinned =>
      _messagePinnedController.stream;

  final StreamController<String> _messageUnpinnedController =
      StreamController<String>.broadcast();
  Stream<String> get onMessageUnpinned => _messageUnpinnedController.stream;

  final StreamController<Map<String, dynamic>> _messageEditedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageEdited =>
      _messageEditedController.stream;

  final StreamController<Map<String, dynamic>> _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedController.stream;

  final StreamController<Map<String, dynamic>> _reactionAddedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onReactionAdded =>
      _reactionAddedController.stream;

  final StreamController<Map<String, dynamic>> _reactionRemovedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onReactionRemoved =>
      _reactionRemovedController.stream;

  final StreamController<Map<String, dynamic>> _groupUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onGroupUpdated =>
      _groupUpdatedController.stream;

  final StreamController<Map<String, dynamic>> _chatCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onChatCreated =>
      _chatCreatedController.stream;

  final StreamController<Map<String, dynamic>> _userOnlineStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onUserOnlineStatus =>
      _userOnlineStatusController.stream;

  void connectGlobal(List<String> chatIds) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('user-connected', {'userId': _userId, 'chatIds': chatIds});
      for (final id in chatIds) {
        _socket!.emit('join-chat', {'chatId': id, 'userId': _userId});
      }
      return;
    }
    _socket = io.io(ApiConfig.socketUrl,
        io.OptionBuilder().setTransports(['websocket', 'polling']).build());

    _socket!.onConnect((_) {
      _socket!.emit('user-connected', {'userId': _userId, 'chatIds': chatIds});
      for (final id in chatIds) {
        _socket!.emit('join-chat', {'chatId': id, 'userId': _userId});
      }
    });

    _socket!.on('receive-message', (data) {
      if (data is Map && data['chatId'] != null) {
        try {
          final msg =
              MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
          _receiveMessageController.add(msg);
        } catch (_) {}
      }
    });

    _socket!.on('message-status-update', (data) {
      if (data is Map) {
        _messageStatusController.add(Map<String, dynamic>.from(data as Map));
      }
    });

    _socket!.on('user-typing', (data) {
      if (data is Map && data['userName'] != null) {
        _userTypingController.add(data['userName'].toString());
      }
    });

    _socket!.on('user-stop-typing', (_) => _userStopTypingController.add(null));

    _socket!.on('message-pinned', (data) {
      if (data is Map)
        _messagePinnedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('message-unpinned', (data) {
      if (data is Map && data['messageId'] != null) {
        _messageUnpinnedController.add(data['messageId'].toString());
      }
    });

    _socket!.on('chat-created', (data) {
      if (data is Map)
        _chatCreatedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('user-online-status', (data) {
      if (data is Map)
        _userOnlineStatusController.add(Map<String, dynamic>.from(data as Map));
    });
  }

  void joinChat(String chatId) {
    _currentChatId = chatId;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join-chat', {'chatId': chatId, 'userId': _userId});
    }
  }

  void leaveChat(String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave-chat', {'chatId': chatId, 'userId': _userId});
    }
    if (_currentChatId == chatId) _currentChatId = null;
  }

  void subscribeChatRoom(String chatId) {
    _socket?.on('message-edited', (data) {
      if (data is Map)
        _messageEditedController.add(Map<String, dynamic>.from(data as Map));
    });
    _socket?.on('message-deleted', (data) {
      if (data is Map)
        _messageDeletedController.add(Map<String, dynamic>.from(data as Map));
    });
    _socket?.on('reaction-added', (data) {
      if (data is Map)
        _reactionAddedController.add(Map<String, dynamic>.from(data as Map));
    });
    _socket?.on('reaction-removed', (data) {
      if (data is Map)
        _reactionRemovedController.add(Map<String, dynamic>.from(data as Map));
    });
    _socket?.on('group-updated', (data) {
      if (data is Map)
        _groupUpdatedController.add(Map<String, dynamic>.from(data as Map));
    });
  }

  void sendMessage(String chatId, String content,
      {String? messageId,
      String? replyToId,
      String? replyToContent,
      String? replyToSender}) {
    if (_socket == null || !_socket!.connected) return;
    final message = {
      'id': messageId,
      'chatId': chatId,
      'content': content,
      'senderId': _userId,
      'senderName': _userName,
      'timestamp': DateTime.now().toIso8601String(),
      if (replyToId != null && replyToContent != null && replyToSender != null)
        'replyTo': {
          'id': replyToId,
          'content': replyToContent,
          'sender': replyToSender
        },
    };
    _socket!.emit('send-message', {'chatId': chatId, 'message': message});
  }

  void sendTyping(String chatId) {
    _socket?.emit(
        'typing', {'chatId': chatId, 'userId': _userId, 'userName': _userName});
  }

  void sendStopTyping(String chatId) {
    _socket?.emit('stop-typing', {'chatId': chatId, 'userId': _userId});
  }

  void markMessageDelivered(String chatId, String messageId, String senderId) {
    _socket?.emit('message-delivered',
        {'chatId': chatId, 'messageId': messageId, 'senderId': senderId});
  }

  void markMessageSeen(String chatId, String messageId, String senderId) {
    _socket?.emit('message-seen',
        {'chatId': chatId, 'messageId': messageId, 'senderId': senderId});
  }

  void markMessagesSeen(
      String chatId, List<String> messageIds, String senderId) {
    _socket?.emit('messages-seen',
        {'chatId': chatId, 'messageIds': messageIds, 'senderId': senderId});
  }

  void markGroupMessagesSeen(String chatId, List<String> messageIds) {
    _socket?.emit('group-message-seen', {
      'chatId': chatId,
      'messageIds': messageIds,
      'userId': _userId,
      'userName': _userName
    });
  }

  void pinMessage(String chatId, String messageId, String duration,
      String expiresAt, String messageContent, String messageSender) {
    _socket?.emit('pin-message', {
      'chatId': chatId,
      'messageId': messageId,
      'pinnedBy': _userId,
      'duration': duration,
      'expiresAt': expiresAt,
      'messageContent': messageContent,
      'messageSender': messageSender,
    });
  }

  void unpinMessage(String chatId, String messageId) {
    _socket?.emit('unpin-message', {'chatId': chatId, 'messageId': messageId});
  }

  void editMessage(String chatId, String messageId, String newContent,
      String editedAt, String originalContent) {
    _socket?.emit('edit-message', {
      'chatId': chatId,
      'messageId': messageId,
      'newContent': newContent,
      'editedAt': editedAt,
      'originalContent': originalContent,
    });
  }

  void deleteMessage(String chatId, String messageId, bool deleteForEveryone) {
    _socket?.emit('delete-message', {
      'chatId': chatId,
      'messageId': messageId,
      'deleteForEveryone': deleteForEveryone
    });
  }

  void addReaction(String chatId, String messageId, String emoji) {
    _socket?.emit('add-reaction', {
      'chatId': chatId,
      'messageId': messageId,
      'userId': _userId,
      'userName': _userName,
      'emoji': emoji
    });
  }

  void removeReaction(String chatId, String messageId, String emoji) {
    _socket?.emit('remove-reaction', {
      'chatId': chatId,
      'messageId': messageId,
      'userId': _userId,
      'emoji': emoji
    });
  }

  void notifyNewChatCreated(String chatId, Map<String, dynamic> chatData,
      List<String> participantIds) {
    _socket?.emit('new-chat-created', {
      'chatId': chatId,
      'chatData': chatData,
      'participantIds': participantIds
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentChatId = null;
  }

  void dispose() {
    disconnect();
    _receiveMessageController.close();
    _messageStatusController.close();
    _userTypingController.close();
    _userStopTypingController.close();
    _messagePinnedController.close();
    _messageUnpinnedController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    _reactionAddedController.close();
    _reactionRemovedController.close();
    _groupUpdatedController.close();
    _chatCreatedController.close();
    _userOnlineStatusController.close();
  }
}
