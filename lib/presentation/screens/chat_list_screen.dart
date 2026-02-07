import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:softex_chat_app/core/utils/time_utils.dart';

import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../logic/chat_list/chat_list_controller.dart';
import '../widgets/custom_app_bar.dart';
import '../../services/storage_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  UserModelInfo _buildUserInfo(ChatModel chat) {
    final currentUserId = StorageService.userId ?? '';
    final participants = chat.participants ?? [];
    if (chat.isGroup || participants.isEmpty) {
      return const UserModelInfo();
    }
    final other = participants.firstWhere(
      (u) => u.id != currentUserId,
      orElse: () => participants.first,
    );
    return UserModelInfo(
      name: other.name,
      avatar: other.avatar,
      isOnline: other.isOnline,
    );
  }

  Widget _buildReadStatusIcon(MessageModel? lastMessage) {
    if (lastMessage == null) return const SizedBox.shrink();
    final status = lastMessage.status;
    if (status == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    switch (status) {
      case 'seen':
        icon = Icons.done_all;
        color = Colors.blueAccent;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'sent':
      default:
        icon = Icons.done;
        color = Colors.grey;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final ChatListController c = Get.put(ChatListController());
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
        title: 'Chats',
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: c.openProfile)
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.chats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value.isNotEmpty && c.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.error.value, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: c.loadChats, child: const Text('Retry')),
              ],
            ),
          );
        }
        if (c.chats.isEmpty) {
          return const Center(child: Text('No chats. Start a new chat.'));
        }
        return RefreshIndicator(
          onRefresh: c.loadChats,
          child: ListView.builder(
            itemCount: c.chats.length,
            itemBuilder: (_, i) {
              final chat = c.chats[i];
              final last = chat.lastMessage;
              final isLastFromMe = last != null &&
                  last.senderId == (StorageService.userId ?? '');
              final userInfo = _buildUserInfo(chat);
              final time = TimeUtils.formatChatTime(
                last?.createdAt ?? chat.updatedAt,
              );

              final unread = chat.unreadCount ?? 0;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      child: chat.avatar != null && chat.avatar!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                chat.avatar!,
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                              ),
                            )
                          : Text(
                              (chat.isGroup
                                      ? (chat.name ?? 'Group')
                                      : (userInfo.name ?? chat.name ?? 'Chat'))
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                    ),
                    if (!chat.isGroup && userInfo.isOnline == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  chat.isGroup
                      ? (chat.name ?? 'Group')
                      : (userInfo.name ?? chat.name ?? 'Chat'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    if (isLastFromMe) ...[
                      _buildReadStatusIcon(last),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        last?.content ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () => c.openChat(chat),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: c.openNewChat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('New Chat'),
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class UserModelInfo {
  final String? name;
  final String? avatar;
  final bool? isOnline;

  const UserModelInfo({this.name, this.avatar, this.isOnline});
}
