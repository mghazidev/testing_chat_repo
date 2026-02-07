// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// import '../../data/models/message_model.dart';
// import '../../logic/chat_room/chat_room_controller.dart';
// import '../widgets/custom_app_bar.dart';

// class ChatRoomScreen extends StatefulWidget {
//   const ChatRoomScreen({Key? key}) : super(key: key);

//   @override
//   State<ChatRoomScreen> createState() => _ChatRoomScreenState();
// }

// class _ChatRoomScreenState extends State<ChatRoomScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _textController = TextEditingController();
//   final ImagePicker _imagePicker = ImagePicker();

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _pickImage(ChatRoomController c, ImageSource source) async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(source: source);
//       if (image != null) {
//         // Show loading
//         Get.dialog(
//           const Center(child: CircularProgressIndicator()),
//           barrierDismissible: false,
//         );

//         // TODO: Upload to your server and get URL
//         // For now, using placeholder
//         final file = File(image.path);
//         final fileSize = await file.length();

//         // Replace this with actual upload logic
//         final uploadedUrl = await _uploadFile(file);

//         Get.back(); // Close loading

//         await c.sendFile(
//           fileUrl: uploadedUrl,
//           fileName: image.name,
//           fileSize: fileSize,
//           fileType: 'image/jpeg',
//           type: 'image',
//         );

//         _scrollToBottom();
//       }
//     } catch (e) {
//       Get.back(); // Close loading if open
//       Get.snackbar('Error', 'Failed to send image: $e');
//     }
//   }

//   Future<void> _pickDocument(ChatRoomController c) async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
//       );

//       if (result != null && result.files.single.path != null) {
//         // Show loading
//         Get.dialog(
//           const Center(child: CircularProgressIndicator()),
//           barrierDismissible: false,
//         );

//         final file = File(result.files.single.path!);
//         final fileSize = await file.length();

//         // Replace this with actual upload logic
//         final uploadedUrl = await _uploadFile(file);

//         Get.back(); // Close loading

//         await c.sendFile(
//           fileUrl: uploadedUrl,
//           fileName: result.files.single.name,
//           fileSize: fileSize,
//           fileType: result.files.single.extension ?? 'document',
//           type: 'document',
//         );

//         _scrollToBottom();
//       }
//     } catch (e) {
//       Get.back(); // Close loading if open
//       Get.snackbar('Error', 'Failed to send document: $e');
//     }
//   }

//   Future<String> _uploadFile(File file) async {
//     // TODO: Implement actual file upload to your server
//     // This is a placeholder - replace with your upload logic
//     // Example:
//     // final formData = FormData.fromMap({
//     //   'file': await MultipartFile.fromFile(file.path),
//     // });
//     // final response = await dio.post('/upload', data: formData);
//     // return response.data['url'];

//     // For now, returning placeholder
//     await Future.delayed(const Duration(seconds: 1));
//     return 'https://placeholder-url.com/${file.path.split('/').last}';
//   }

//   void _showAttachmentOptions(BuildContext context, ChatRoomController c) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_camera, color: Colors.blue),
//               title: const Text('Camera'),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _pickImage(c, ImageSource.camera);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library, color: Colors.purple),
//               title: const Text('Gallery'),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _pickImage(c, ImageSource.gallery);
//               },
//             ),
//             ListTile(
//               leading:
//                   const Icon(Icons.insert_drive_file, color: Colors.orange),
//               title: const Text('Document'),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _pickDocument(c);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     final chatId = args?['chatId'] as String? ?? '';
//     final ChatRoomController c = Get.put(
//       ChatRoomController(chatId: chatId),
//       tag: chatId,
//     );

//     return Scaffold(
//       appBar: CustomAppBar(
//         titleWidget: Obx(() {
//           final chat = c.chat.value;
//           if (chat == null) return const Text('Chat');
//           final isGroup = chat.isGroup;
//           String title = chat.name ?? 'Chat';
//           String? subtitle;

//           if (!isGroup && (chat.participants ?? []).isNotEmpty) {
//             final meId = c.currentUserId;
//             final others =
//                 (chat.participants ?? []).where((u) => u.id != meId).toList();
//             if (others.isNotEmpty) {
//               final other = others.first;
//               title = other.name ?? title;

//               final isOnline = c.participantOnlineStatus[other.id]?.value ??
//                   other.isOnline ??
//                   false;
//               final lastSeen =
//                   c.participantLastSeen[other.id]?.value ?? other.lastSeen;

//               if (isOnline) {
//                 subtitle = 'Online';
//               } else if (lastSeen != null) {
//                 subtitle = _formatLastSeen(lastSeen);
//               }
//             }
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title),
//               if (subtitle != null)
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: subtitle == 'Online'
//                         ? Colors.greenAccent
//                         : Colors.grey[400],
//                   ),
//                 ),
//             ],
//           );
//         }),
//         centerTitle: false,
//         actions: [
//           if (c.chat.value?.isGroup == true)
//             IconButton(
//                 icon: const Icon(Icons.info_outline),
//                 onPressed: c.openGroupInfo),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Pinned message bar
//           Obx(() {
//             if (c.pinnedMessage.value != null) {
//               return Container(
//                 color: Colors.grey[800],
//                 child: ListTile(
//                   leading: const Icon(Icons.push_pin, size: 20),
//                   title: Text(
//                     c.pinnedMessage.value!.content ?? '',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.close, size: 20),
//                     onPressed: () {
//                       if (c.pinnedMessage.value?.messageId != null) {
//                         c.unpinMessage(c.pinnedMessage.value!.messageId);
//                       }
//                     },
//                   ),
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),

//           // Reply bar
//           Obx(() {
//             if (c.replyingToMessage.value != null) {
//               final replyMsg = c.replyingToMessage.value!;
//               return Container(
//                 color: Colors.grey[850],
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 4,
//                       height: 48,
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             replyMsg.senderName ?? 'Unknown',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                               color: Colors.blue,
//                             ),
//                           ),
//                           Text(
//                             replyMsg.content,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[400],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, size: 20),
//                       onPressed: c.cancelReply,
//                     ),
//                   ],
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),

//           // Messages
//           Expanded(
//             child: Obx(() {
//               if (c.isLoading.value && c.messages.isEmpty) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (c.error.value.isNotEmpty && c.messages.isEmpty) {
//                 return Center(child: Text(c.error.value));
//               }

//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _scrollToBottom();
//               });

//               return ListView.builder(
//                 controller: _scrollController,
//                 reverse: false,
//                 itemCount: c.messages.length,
//                 itemBuilder: (_, i) {
//                   final msg = c.messages[i];
//                   return _MessageBubble(
//                     key: ValueKey(msg.id),
//                     controller: c,
//                     message: msg,
//                     onLongPress: () => _showMessageActions(
//                         context, c, msg, msg.senderId == c.currentUserId),
//                   );
//                 },
//               );
//             }),
//           ),

//           // Typing indicator
//           Obx(() {
//             if (c.typingUser.value.isNotEmpty) {
//               return Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Text(
//                   '${c.typingUser.value} is typing...',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[400]),
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),

//           // Input area
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(30),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 6,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.emoji_emotions_outlined,
//                               color: Colors.grey[600]),
//                           onPressed: () {},
//                           splashRadius: 20,
//                         ),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: TextField(
//                             controller: _textController,
//                             decoration: const InputDecoration(
//                               hintText: 'Message',
//                               border: InputBorder.none,
//                               isDense: true,
//                               contentPadding:
//                                   EdgeInsets.symmetric(vertical: 12),
//                             ),
//                             onChanged: (_) => c.sendTyping(),
//                             onSubmitted: (v) {
//                               if (v.trim().isNotEmpty) {
//                                 c.sendText(v.trim());
//                                 _textController.clear();
//                                 c.stopTyping();
//                                 _scrollToBottom();
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         IconButton(
//                           icon:
//                               Icon(Icons.attach_file, color: Colors.grey[600]),
//                           onPressed: () => _showAttachmentOptions(context, c),
//                           splashRadius: 20,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: () {
//                     final t = _textController.text.trim();
//                     if (t.isNotEmpty) {
//                       c.sendText(t);
//                       _textController.clear();
//                       c.stopTyping();
//                       _scrollToBottom();
//                     }
//                   },
//                   child: Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.primary,
//                       shape: BoxShape.circle,
//                       boxShadow: const [
//                         BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 6,
//                             offset: Offset(0, 2))
//                       ],
//                     ),
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatLastSeen(DateTime lastSeen) {
//     final now = DateTime.now();
//     final difference = now.difference(lastSeen);

//     if (difference.inMinutes < 1) {
//       return 'Last seen just now';
//     } else if (difference.inMinutes < 60) {
//       return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
//     } else if (difference.inHours < 24) {
//       return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
//     } else if (difference.inDays < 7) {
//       return 'Last seen ${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
//     } else {
//       return 'Last seen ${DateFormat('MMM d').format(lastSeen)}';
//     }
//   }

//   void _showEditDialog(
//       BuildContext context, ChatRoomController c, MessageModel msg) {
//     final controller = TextEditingController(text: msg.content);
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Edit message'),
//         content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(border: OutlineInputBorder()),
//             maxLines: 2),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () {
//               final t = controller.text.trim();
//               if (t.isNotEmpty) {
//                 c.editMessage(msg.id, t);
//                 Navigator.pop(ctx);
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMessageActions(
//     BuildContext context,
//     ChatRoomController c,
//     MessageModel msg,
//     bool isMe,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) {
//         return SafeArea(
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Reply option (for everyone)
//                 ListTile(
//                   leading: const Icon(Icons.reply),
//                   title: const Text('Reply'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.setReplyMessage(msg);
//                   },
//                 ),

//                 // Copy option (for everyone)
//                 if (msg.type == 'text')
//                   ListTile(
//                     leading: const Icon(Icons.copy),
//                     title: const Text('Copy'),
//                     onTap: () {
//                       Navigator.pop(ctx);
//                       c.copyMessage(msg.content);
//                     },
//                   ),

//                 // Forward option (for everyone)
//                 ListTile(
//                   leading: const Icon(Icons.forward),
//                   title: const Text('Forward'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.forwardMessage(msg);
//                   },
//                 ),

//                 // Edit (only for sender)
//                 if (isMe && msg.type == 'text')
//                   ListTile(
//                     leading: const Icon(Icons.edit),
//                     title: const Text('Edit message'),
//                     onTap: () {
//                       Navigator.pop(ctx);
//                       _showEditDialog(context, c, msg);
//                     },
//                   ),

//                 // Delete for me (only for sender)
//                 if (isMe)
//                   ListTile(
//                     leading: const Icon(Icons.delete_outline),
//                     title: const Text('Delete for me'),
//                     onTap: () {
//                       Navigator.pop(ctx);
//                       c.deleteMessage(msg.id, deleteForEveryone: false);
//                     },
//                   ),

//                 // Delete for everyone (only for sender)
//                 if (isMe)
//                   ListTile(
//                     leading: const Icon(Icons.delete_forever),
//                     title: const Text('Delete for everyone'),
//                     onTap: () {
//                       Navigator.pop(ctx);
//                       c.deleteMessage(msg.id, deleteForEveryone: true);
//                     },
//                   ),

//                 // Pin options
//                 ListTile(
//                   leading: const Icon(Icons.push_pin_outlined),
//                   title: const Text('Pin for 24 hours'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.pinMessage(msg.id, '24h');
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.push_pin),
//                   title: const Text('Pin for 7 days'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.pinMessage(msg.id, '7d');
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.push_pin),
//                   title: const Text('Pin for 30 days'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.pinMessage(msg.id, '30d');
//                   },
//                 ),
//                 if (c.pinnedMessage.value?.messageId == msg.id)
//                   ListTile(
//                     leading: const Icon(Icons.push_pin),
//                     title: const Text('Unpin'),
//                     onTap: () {
//                       Navigator.pop(ctx);
//                       c.unpinMessage(msg.id);
//                     },
//                   ),

//                 const Divider(),

//                 // Reactions
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'React:',
//                         style: TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children: ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏']
//                             .map(
//                               (emoji) => InkWell(
//                                 onTap: () {
//                                   Navigator.pop(ctx);
//                                   c.toggleReaction(msg.id, emoji);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade800,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     emoji,
//                                     style: const TextStyle(fontSize: 24),
//                                   ),
//                                 ),
//                               ),
//                             )
//                             .toList(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // Message bubble widget with proper reactive rendering
// class _MessageBubble extends StatelessWidget {
//   final ChatRoomController controller;
//   final MessageModel message;
//   final VoidCallback onLongPress;

//   const _MessageBubble({
//     Key? key,
//     required this.controller,
//     required this.message,
//     required this.onLongPress,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final isMe = message.senderId == controller.currentUserId;

//     return Obx(() {
//       // Get current message state
//       final currentMsg =
//           controller.messages.firstWhereOrNull((m) => m.id == message.id) ??
//               message;

//       // Get read receipts reactively
//       final readReceipts =
//           controller.readReceiptsByMessage[message.id]?.toList() ?? [];

//       // Determine status for sent messages
//       String statusText = '';
//       IconData? statusIcon;
//       Color? statusColor;

//       if (isMe) {
//         if (readReceipts.isNotEmpty) {
//           statusText = 'Seen';
//           statusIcon = Icons.done_all;
//           statusColor = Colors.lightBlueAccent;
//         } else if (currentMsg.status == 'delivered') {
//           statusText = 'Delivered';
//           statusIcon = Icons.done_all;
//           statusColor = Colors.white70;
//         } else {
//           statusText = 'Sent';
//           statusIcon = Icons.done;
//           statusColor = Colors.white70;
//         }
//       }

//       return Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: GestureDetector(
//           onLongPress: onLongPress,
//           child: Column(
//             crossAxisAlignment:
//                 isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isMe
//                       ? Colors.blueAccent.withOpacity(0.8)
//                       : Colors.grey.shade800,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Show sender name in groups
//                     if (controller.chat.value?.isGroup == true && !isMe)
//                       Text(
//                         currentMsg.senderName ?? currentMsg.senderId,
//                         style: const TextStyle(
//                             fontSize: 12, fontWeight: FontWeight.w600),
//                       ),

//                     // Reply indicator
//                     if (currentMsg.replyToId != null)
//                       Container(
//                         margin: const EdgeInsets.only(bottom: 4),
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Colors.black26,
//                           borderRadius: BorderRadius.circular(4),
//                           border: Border(
//                             left: BorderSide(color: Colors.white70, width: 3),
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               currentMsg.replyToSender ?? 'Unknown',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white70,
//                               ),
//                             ),
//                             Text(
//                               currentMsg.replyToContent ?? '',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.white60,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                     // Message content
//                     if (currentMsg.type == 'image')
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           currentMsg.fileUrl ?? '',
//                           width: 200,
//                           height: 200,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Container(
//                             width: 200,
//                             height: 200,
//                             color: Colors.grey,
//                             child: const Icon(Icons.broken_image),
//                           ),
//                         ),
//                       )
//                     else if (currentMsg.type == 'document')
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(Icons.insert_drive_file, size: 32),
//                           const SizedBox(width: 8),
//                           Flexible(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   currentMsg.fileName ?? 'Document',
//                                   style: const TextStyle(color: Colors.white),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 if (currentMsg.fileSize != null)
//                                   Text(
//                                     '${(currentMsg.fileSize! / 1024).toStringAsFixed(1)} KB',
//                                     style: const TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.white70,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       )
//                     else
//                       Text(
//                         currentMsg.content,
//                         style: const TextStyle(color: Colors.white),
//                       ),

//                     // Edited indicator
//                     if (currentMsg.isEdited == true)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 2),
//                         child: Text(
//                           'Edited',
//                           style: TextStyle(
//                             fontSize: 9,
//                             color: Colors.white60,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 4),

//                     // Time and status
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           _formatTime(currentMsg.createdAt),
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: Colors.white70,
//                           ),
//                         ),
//                         if (isMe && statusIcon != null) ...[
//                           const SizedBox(width: 6),
//                           Icon(
//                             statusIcon,
//                             size: 14,
//                             color: statusColor,
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Reactions (using Obx for reactivity)
//               Obx(() {
//                 final reactions =
//                     controller.reactionsByMessage[message.id]?.toList() ?? [];

//                 if (reactions.isEmpty) {
//                   return const SizedBox.shrink();
//                 }

//                 return Container(
//                   margin: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.black26,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Wrap(
//                     spacing: 4,
//                     children: reactions
//                         .map(
//                           (r) => GestureDetector(
//                             onTap: () =>
//                                 controller.toggleReaction(message.id, r.emoji),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color:
//                                     r.userIds.contains(controller.currentUserId)
//                                         ? Colors.blue.withOpacity(0.3)
//                                         : Colors.transparent,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: r.userIds
//                                         .contains(controller.currentUserId)
//                                     ? Border.all(color: Colors.blue, width: 1)
//                                     : null,
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     r.emoji,
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                   const SizedBox(width: 2),
//                                   Text(
//                                     r.userIds.length.toString(),
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         )
//                         .toList(),
//                   ),
//                 );
//               }),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   String _formatTime(DateTime? time) {
//     if (time == null) return '';
//     final now = DateTime.now();
//     final diff = now.difference(time);

//     if (diff.inDays == 0) {
//       return DateFormat('HH:mm').format(time);
//     } else if (diff.inDays == 1) {
//       return 'Yesterday ${DateFormat('HH:mm').format(time)}';
//     } else {
//       return DateFormat('MMM d, HH:mm').format(time);
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _pickImage(ChatRoomController c, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // TODO: Upload to your server and get URL
        // For now, using placeholder
        final file = File(image.path);
        final fileSize = await file.length();

        // Replace this with actual upload logic
        final uploadedUrl = await _uploadFile(file);

        Get.back(); // Close loading

        await c.sendFile(
          fileUrl: uploadedUrl,
          fileName: image.name,
          fileSize: fileSize,
          fileType: 'image/jpeg',
          type: 'image',
        );

        _scrollToBottom();
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar('Error', 'Failed to send image: $e');
    }
  }

  Future<void> _pickDocument(ChatRoomController c) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Replace this with actual upload logic
        final uploadedUrl = await _uploadFile(file);

        Get.back(); // Close loading

        await c.sendFile(
          fileUrl: uploadedUrl,
          fileName: result.files.single.name,
          fileSize: fileSize,
          fileType: result.files.single.extension ?? 'document',
          type: 'document',
        );

        _scrollToBottom();
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar('Error', 'Failed to send document: $e');
    }
  }

  Future<String> _uploadFile(File file) async {
    // TODO: Implement actual file upload to your server
    // This is a placeholder - replace with your upload logic
    // Example:
    // final formData = FormData.fromMap({
    //   'file': await MultipartFile.fromFile(file.path),
    // });
    // final response = await dio.post('/upload', data: formData);
    // return response.data['url'];

    // For now, returning placeholder
    await Future.delayed(const Duration(seconds: 1));
    return 'https://placeholder-url.com/${file.path.split('/').last}';
  }

  void _showAttachmentOptions(BuildContext context, ChatRoomController c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(c, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(c, ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument(c);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final chatId = args?['chatId'] as String? ?? '';
    final ChatRoomController c = Get.put(
      ChatRoomController(chatId: chatId),
      tag: chatId,
    );

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

              final isOnline = c.participantOnlineStatus[other.id]?.value ??
                  other.isOnline ??
                  false;
              final lastSeen =
                  c.participantLastSeen[other.id]?.value ?? other.lastSeen;

              if (isOnline) {
                subtitle = 'Online';
              } else if (lastSeen != null) {
                subtitle = _formatLastSeen(lastSeen);
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
          // Pinned message bar
          Obx(() {
            if (c.pinnedMessage.value != null) {
              return Container(
                color: Colors.grey[800],
                child: ListTile(
                  leading: const Icon(Icons.push_pin, size: 20),
                  title: Text(
                    c.pinnedMessage.value!.content ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      if (c.pinnedMessage.value?.messageId != null) {
                        c.unpinMessage(c.pinnedMessage.value!.messageId);
                      }
                    },
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Reply bar
          Obx(() {
            if (c.replyingToMessage.value != null) {
              final replyMsg = c.replyingToMessage.value!;
              return Container(
                color: Colors.grey[850],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyMsg.senderName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            replyMsg.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: c.cancelReply,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Messages
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
                  return _MessageBubble(
                    key: ValueKey(msg.id),
                    controller: c,
                    message: msg,
                    onLongPress: () => _showMessageActions(
                        context, c, msg, msg.senderId == c.currentUserId),
                  );
                },
              );
            }),
          ),

          // Typing indicator
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

          // Input area
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
                      boxShadow: const [
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
                          onPressed: () => _showAttachmentOptions(context, c),
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
                      boxShadow: const [
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply option (for everyone)
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.setReplyMessage(msg);
                  },
                ),

                // Copy option (for everyone)
                if (msg.type == 'text')
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy'),
                    onTap: () {
                      Navigator.pop(ctx);
                      c.copyMessage(msg.content);
                    },
                  ),

                // Forward option (for everyone)
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.forwardMessage(msg);
                  },
                ),

                // Edit (only for sender)
                if (isMe && msg.type == 'text')
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit message'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditDialog(context, c, msg);
                    },
                  ),

                // Delete for me (only for sender)
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete for me'),
                    onTap: () {
                      Navigator.pop(ctx);
                      c.deleteMessage(msg.id, deleteForEveryone: false);
                    },
                  ),

                // Delete for everyone (only for sender)
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Delete for everyone'),
                    onTap: () {
                      Navigator.pop(ctx);
                      c.deleteMessage(msg.id, deleteForEveryone: true);
                    },
                  ),

                // Pin options
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

                // Reactions
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
          ),
        );
      },
    );
  }
}

// Message bubble widget with proper reactive rendering
class _MessageBubble extends StatelessWidget {
  final ChatRoomController controller;
  final MessageModel message;
  final VoidCallback onLongPress;

  const _MessageBubble({
    Key? key,
    required this.controller,
    required this.message,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == controller.currentUserId;

    return Obx(() {
      // Get current message state
      final currentMsg =
          controller.messages.firstWhereOrNull((m) => m.id == message.id) ??
              message;

      // Get read receipts reactively
      final readReceipts =
          controller.readReceiptsByMessage[message.id]?.toList() ?? [];

      // Determine status for sent messages
      String statusText = '';
      IconData? statusIcon;
      Color? statusColor;

      if (isMe) {
        if (readReceipts.isNotEmpty) {
          statusText = 'Seen';
          statusIcon = Icons.done_all;
          statusColor = Colors.lightBlueAccent;
        } else if (currentMsg.status == 'delivered') {
          statusText = 'Delivered';
          statusIcon = Icons.done_all;
          statusColor = Colors.white70;
        } else {
          statusText = 'Sent';
          statusIcon = Icons.done;
          statusColor = Colors.white70;
        }
      }

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // Show sender name in groups
                    if (controller.chat.value?.isGroup == true && !isMe)
                      Text(
                        currentMsg.senderName ?? currentMsg.senderId,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),

                    // Reply indicator
                    if (currentMsg.replyToId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                          border: Border(
                            left: BorderSide(color: Colors.white70, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentMsg.replyToSender ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              currentMsg.replyToContent ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message content
                    if (currentMsg.type == 'image')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentMsg.fileUrl ?? '',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      )
                    else if (currentMsg.type == 'document')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file, size: 32),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentMsg.fileName ?? 'Document',
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (currentMsg.fileSize != null)
                                  Text(
                                    '${(currentMsg.fileSize! / 1024).toStringAsFixed(1)} KB',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        currentMsg.content,
                        style: const TextStyle(color: Colors.white),
                      ),

                    // Edited indicator
                    if (currentMsg.isEdited == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Edited',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white60,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Time and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(currentMsg.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                        if (isMe && statusIcon != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions (using Obx for reactivity)
              Obx(() {
                final reactions =
                    controller.reactionsByMessage[message.id]?.toList() ?? [];

                if (reactions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                controller.toggleReaction(message.id, r.emoji),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    r.userIds.contains(controller.currentUserId)
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: r.userIds
                                        .contains(controller.currentUserId)
                                    ? Border.all(color: Colors.blue, width: 1)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.emoji,
                                    style: const TextStyle(fontSize: 14),
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
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(time);
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:softex_chat_app/core/utils/time_utils.dart';

// import '../../data/models/message_model.dart';
// import '../../logic/chat_room/chat_room_controller.dart';
// import '../widgets/custom_app_bar.dart';

// class ChatRoomScreen extends StatefulWidget {
//   const ChatRoomScreen({Key? key}) : super(key: key);

//   @override
//   State<ChatRoomScreen> createState() => _ChatRoomScreenState();
// }

// class _ChatRoomScreenState extends State<ChatRoomScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _textController = TextEditingController();

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     final chatId = args?['chatId'] as String? ?? '';
//     final ChatRoomController c = Get.put(ChatRoomController(), tag: chatId);

//     return Scaffold(
//       appBar: CustomAppBar(
//         titleWidget: Obx(() {
//           final chat = c.chat.value;
//           if (chat == null) return const Text('Chat');
//           final isGroup = chat.isGroup;
//           String title = chat.name ?? 'Chat';
//           String? subtitle;

//           if (!isGroup && (chat.participants ?? []).isNotEmpty) {
//             final meId = c.currentUserId;
//             final others =
//                 (chat.participants ?? []).where((u) => u.id != meId).toList();
//             if (others.isNotEmpty) {
//               final other = others.first;
//               title = other.name ?? title;

//               final isOnline = c.participantOnlineStatus[other.id] ??
//                   other.isOnline ??
//                   false;
//               final lastSeen =
//                   c.participantLastSeen[other.id] ?? other.lastSeen;

//               if (isOnline) {
//                 subtitle = 'Online';
//               } else if (lastSeen != null) {
//                 subtitle = _formatLastSeen(lastSeen);
//               }
//             }
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title),
//               if (subtitle != null)
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: subtitle == 'Online'
//                         ? Colors.greenAccent
//                         : Colors.grey[400],
//                   ),
//                 ),
//             ],
//           );
//         }),
//         centerTitle: false,
//         actions: [
//           if (c.chat.value?.isGroup == true)
//             IconButton(
//                 icon: const Icon(Icons.info_outline),
//                 onPressed: c.openGroupInfo),
//         ],
//       ),
//       body: Column(
//         children: [
//           Obx(() {
//             if (c.pinnedMessage.value != null) {
//               return ListTile(
//                 tileColor: Colors.grey[800],
//                 leading: const Icon(Icons.push_pin, size: 20),
//                 title: Text(c.pinnedMessage.value!.content ?? '',
//                     maxLines: 1, overflow: TextOverflow.ellipsis),
//               );
//             }
//             return const SizedBox.shrink();
//           }),
//           Expanded(
//             child: Obx(() {
//               // CRITICAL: Use the trigger to force rebuilds
//               // final _ = c._messageUpdateTrigger.value;
//               final _ = c.messageUpdateTrigger.value;

//               if (c.isLoading.value && c.messages.isEmpty) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (c.error.value.isNotEmpty && c.messages.isEmpty) {
//                 return Center(child: Text(c.error.value));
//               }

//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _scrollToBottom();
//               });

//               return ListView.builder(
//                 controller: _scrollController,
//                 reverse: false,
//                 itemCount: c.messages.length,
//                 itemBuilder: (_, i) {
//                   final msg = c.messages[i];
//                   return _MessageBubble(
//                     key: ValueKey(msg.id),
//                     controller: c,
//                     message: msg,
//                     onLongPress: () => _showMessageActions(
//                         context, c, msg, msg.senderId == c.currentUserId),
//                   );
//                 },
//               );
//             }),
//           ),
//           Obx(() {
//             if (c.typingUser.value.isNotEmpty) {
//               return Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Text(
//                   '${c.typingUser.value} is typing...',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[400]),
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(30),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 6,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.emoji_emotions_outlined,
//                               color: Colors.grey[600]),
//                           onPressed: () {},
//                           splashRadius: 20,
//                         ),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: TextField(
//                             controller: _textController,
//                             decoration: const InputDecoration(
//                               hintText: 'Message',
//                               border: InputBorder.none,
//                               isDense: true,
//                               contentPadding:
//                                   EdgeInsets.symmetric(vertical: 12),
//                             ),
//                             onChanged: (_) => c.sendTyping(),
//                             onSubmitted: (v) {
//                               if (v.trim().isNotEmpty) {
//                                 c.sendText(v.trim());
//                                 _textController.clear();
//                                 c.stopTyping();
//                                 _scrollToBottom();
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         IconButton(
//                           icon:
//                               Icon(Icons.attach_file, color: Colors.grey[600]),
//                           onPressed: () {},
//                           splashRadius: 20,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: () {
//                     final t = _textController.text.trim();
//                     if (t.isNotEmpty) {
//                       c.sendText(t);
//                       _textController.clear();
//                       c.stopTyping();
//                       _scrollToBottom();
//                     }
//                   },
//                   child: Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.primary,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 6,
//                             offset: Offset(0, 2))
//                       ],
//                     ),
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatLastSeen(DateTime lastSeen) {
//     final now = DateTime.now();
//     final difference = now.difference(lastSeen);

//     if (difference.inMinutes < 1) {
//       return 'Last seen just now';
//     } else if (difference.inMinutes < 60) {
//       return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
//     } else if (difference.inHours < 24) {
//       return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
//     } else if (difference.inDays < 7) {
//       return 'Last seen ${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
//     } else {
//       return 'Last seen ${DateFormat('MMM d').format(lastSeen)}';
//     }
//   }

//   void _showEditDialog(
//       BuildContext context, ChatRoomController c, MessageModel msg) {
//     final controller = TextEditingController(text: msg.content);
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Edit message'),
//         content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(border: OutlineInputBorder()),
//             maxLines: 2),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () {
//               final t = controller.text.trim();
//               if (t.isNotEmpty) {
//                 c.editMessage(msg.id, t);
//                 Navigator.pop(ctx);
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMessageActions(
//     BuildContext context,
//     ChatRoomController c,
//     MessageModel msg,
//     bool isMe,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (isMe)
//                 ListTile(
//                   leading: const Icon(Icons.edit),
//                   title: const Text('Edit message'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     _showEditDialog(context, c, msg);
//                   },
//                 ),
//               if (isMe)
//                 ListTile(
//                   leading: const Icon(Icons.delete_outline),
//                   title: const Text('Delete for me'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.deleteMessage(msg.id, deleteForEveryone: false);
//                   },
//                 ),
//               if (isMe)
//                 ListTile(
//                   leading: const Icon(Icons.delete_forever),
//                   title: const Text('Delete for everyone'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.deleteMessage(msg.id, deleteForEveryone: true);
//                   },
//                 ),
//               ListTile(
//                 leading: const Icon(Icons.push_pin_outlined),
//                 title: const Text('Pin for 24 hours'),
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   c.pinMessage(msg.id, '24h');
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.push_pin),
//                 title: const Text('Pin for 7 days'),
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   c.pinMessage(msg.id, '7d');
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.push_pin),
//                 title: const Text('Pin for 30 days'),
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   c.pinMessage(msg.id, '30d');
//                 },
//               ),
//               if (c.pinnedMessage.value?.messageId == msg.id)
//                 ListTile(
//                   leading: const Icon(Icons.push_pin),
//                   title: const Text('Unpin'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     c.unpinMessage(msg.id);
//                   },
//                 ),
//               const Divider(),
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'React:',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       children: ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏']
//                           .map(
//                             (emoji) => InkWell(
//                               onTap: () {
//                                 Navigator.pop(ctx);
//                                 c.toggleReaction(msg.id, emoji);
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade800,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(
//                                   emoji,
//                                   style: const TextStyle(fontSize: 24),
//                                 ),
//                               ),
//                             ),
//                           )
//                           .toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // CRITICAL: Separate widget for message bubble to ensure proper rebuilding
// class _MessageBubble extends StatelessWidget {
//   final ChatRoomController controller;
//   final MessageModel message;
//   final VoidCallback onLongPress;

//   const _MessageBubble({
//     Key? key,
//     required this.controller,
//     required this.message,
//     required this.onLongPress,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final isMe = message.senderId == controller.currentUserId;

//     // CRITICAL: Wrap entire widget in Obx to react to any changes
//     return Obx(() {
//       // Access the trigger to ensure rebuilds
//       final _ = controller.messageUpdateTrigger.value;

//       // Get the current message from the list (in case it was updated)
//       final currentMsg =
//           controller.messages.firstWhereOrNull((m) => m.id == message.id) ??
//               message;

//       final statusText = isMe
//           ? (currentMsg.status == 'seen'
//               ? 'Seen'
//               : currentMsg.status == 'delivered'
//                   ? 'Delivered'
//                   : 'Sent')
//           : '';

//       return Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: GestureDetector(
//           onLongPress: onLongPress,
//           child: Column(
//             crossAxisAlignment:
//                 isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isMe
//                       ? Colors.blueAccent.withOpacity(0.8)
//                       : Colors.grey.shade800,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (controller.chat.value?.isGroup == true && !isMe)
//                       Text(
//                         currentMsg.senderName ?? currentMsg.senderId,
//                         style: const TextStyle(
//                             fontSize: 12, fontWeight: FontWeight.w600),
//                       ),
//                     Text(
//                       currentMsg.content,
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           TimeUtils.formatChatTime(currentMsg.createdAt),
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: Colors.white70,
//                           ),
//                         ),
//                         if (isMe && statusText.isNotEmpty) ...[
//                           const SizedBox(width: 6),
//                           Icon(
//                             currentMsg.status == 'seen'
//                                 ? Icons.done_all
//                                 : currentMsg.status == 'delivered'
//                                     ? Icons.done_all
//                                     : Icons.done,
//                             size: 14,
//                             color: currentMsg.status == 'seen'
//                                 ? Colors.lightBlueAccent
//                                 : Colors.white70,
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               // CRITICAL: Nested Obx for reactions with proper reactive access
//               Obx(() {
//                 // Access trigger again for this specific section
//                 // final _ = controller._messageUpdateTrigger.value;
//                 final _ = controller.messageUpdateTrigger.value;

//                 // Get reactions from the map
//                 final reactions = controller.reactionsByMessage[message.id];

//                 // If no RxList exists or it's empty, show nothing
//                 if (reactions == null || reactions.isEmpty) {
//                   return const SizedBox.shrink();
//                 }

//                 // Access the RxList value to ensure reactivity
//                 final reactionsList = reactions.toList();

//                 if (reactionsList.isEmpty) {
//                   return const SizedBox.shrink();
//                 }

//                 return Container(
//                   margin: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.black26,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Wrap(
//                     spacing: 4,
//                     children: reactionsList
//                         .map(
//                           (r) => GestureDetector(
//                             onTap: () =>
//                                 controller.toggleReaction(message.id, r.emoji),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color:
//                                     r.userIds.contains(controller.currentUserId)
//                                         ? Colors.blue.withOpacity(0.3)
//                                         : Colors.transparent,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: r.userIds
//                                         .contains(controller.currentUserId)
//                                     ? Border.all(color: Colors.blue, width: 1)
//                                     : null,
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     r.emoji,
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                   const SizedBox(width: 2),
//                                   Text(
//                                     r.userIds.length.toString(),
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         )
//                         .toList(),
//                   ),
//                 );
//               }),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }
