import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:softex_chat_app/core/utils/time_utils.dart';

import '../../data/models/message_model.dart';
import '../../logic/chat_room/chat_room_controller.dart';
import '../widgets/custom_app_bar.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final chatId = args?['chatId'] as String? ?? '';
    final ChatRoomController c = Get.put(ChatRoomController(), tag: chatId);

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Obx(() {
          final chat = c.chat.value;
          if (chat == null) return const Text('Chat');
          final isGroup = chat.isGroup;
          String title = chat.name ?? 'Chat';
          String? subtitle;

          if (!isGroup && (chat.participants ?? []).isNotEmpty) {
            final meId = c.currentUserId;
            final others =
                (chat.participants ?? []).where((u) => u.id != meId).toList();
            if (others.isNotEmpty) {
              final other = others.first;
              title = other.name ?? title;

              if (other.isOnline == true) {
                subtitle = 'Online';
              } else if (other.lastSeen != null) {
                subtitle = _formatLastSeen(other.lastSeen!);
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitle == 'Online'
                        ? Colors.greenAccent
                        : Colors.grey[400],
                  ),
                ),
            ],
          );
        }),
        centerTitle: false,
        actions: [
          if (c.chat.value?.isGroup == true)
            IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: c.openGroupInfo),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (c.pinnedMessage.value != null) {
              return ListTile(
                tileColor: Colors.grey[800],
                leading: const Icon(Icons.push_pin, size: 20),
                title: Text(c.pinnedMessage.value!.content ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.error.value.isNotEmpty && c.messages.isEmpty) {
                return Center(child: Text(c.error.value));
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              return ListView.builder(
                controller: _scrollController,
                reverse: false,
                itemCount: c.messages.length,
                itemBuilder: (_, i) {
                  final msg = c.messages[i];
                  final isMe = msg.senderId == c.currentUserId;
                  final statusText = isMe
                      ? (msg.status == 'seen'
                          ? 'Seen'
                          : msg.status == 'delivered'
                              ? 'Delivered'
                              : 'Sent')
                      : '';

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: () =>
                          _showMessageActions(context, c, msg, isMe),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blueAccent.withOpacity(0.8)
                                  : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.chat.value?.isGroup == true && !isMe)
                                  Text(
                                    msg.senderName ?? msg.senderId,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                Text(
                                  msg.content,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      TimeUtils.formatChatTime(msg.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (isMe && statusText.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        msg.status == 'seen'
                                            ? Icons.done_all
                                            : msg.status == 'delivered'
                                                ? Icons.done_all
                                                : Icons.done,
                                        size: 14,
                                        color: msg.status == 'seen'
                                            ? Colors.lightBlueAccent
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Obx(() {
                            final reactions =
                                c.reactionsByMessage[msg.id] ?? [];

                            if (reactions.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Wrap(
                                spacing: 4,
                                children: reactions
                                    .map(
                                      (r) => GestureDetector(
                                        onTap: () =>
                                            c.toggleReaction(msg.id, r.emoji),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: r.userIds
                                                    .contains(c.currentUserId)
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: r.userIds
                                                    .contains(c.currentUserId)
                                                ? Border.all(
                                                    color: Colors.blue,
                                                    width: 1)
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                r.emoji,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                r.userIds.length.toString(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            if (c.typingUser.value.isNotEmpty) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '${c.typingUser.value} is typing...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined,
                              color: Colors.grey[600]),
                          onPressed: () {},
                          splashRadius: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (_) => c.sendTyping(),
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty) {
                                c.sendText(v.trim());
                                _textController.clear();
                                c.stopTyping();
                                _scrollToBottom();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon:
                              Icon(Icons.attach_file, color: Colors.grey[600]),
                          onPressed: () {},
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final t = _textController.text.trim();
                    if (t.isNotEmpty) {
                      c.sendText(t);
                      _textController.clear();
                      c.stopTyping();
                      _scrollToBottom();
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
    } else {
      return 'Last seen ${DateFormat('MMM d').format(lastSeen)}';
    }
  }

  void _showEditDialog(
      BuildContext context, ChatRoomController c, MessageModel msg) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 2),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                c.editMessage(msg.id, t);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(
    BuildContext context,
    ChatRoomController c,
    MessageModel msg,
    bool isMe,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, c, msg);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete for me'),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.deleteMessage(msg.id, deleteForEveryone: false);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.deleteMessage(msg.id, deleteForEveryone: true);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('Pin for 24 hours'),
                onTap: () {
                  Navigator.pop(ctx);
                  c.pinMessage(msg.id, '24h');
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('Pin for 7 days'),
                onTap: () {
                  Navigator.pop(ctx);
                  c.pinMessage(msg.id, '7d');
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('Pin for 30 days'),
                onTap: () {
                  Navigator.pop(ctx);
                  c.pinMessage(msg.id, '30d');
                },
              ),
              if (c.pinnedMessage.value?.messageId == msg.id)
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: const Text('Unpin'),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.unpinMessage(msg.id);
                  },
                ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'React:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏']
                          .map(
                            (emoji) => InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                c.toggleReaction(msg.id, emoji);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
