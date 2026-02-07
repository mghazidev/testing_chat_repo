import 'package:get/get.dart';

import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/chat_list_screen.dart';
import '../../presentation/screens/chat_room_screen.dart';
import '../../presentation/screens/new_chat_screen.dart';
import '../../presentation/screens/group_info_screen.dart';
import '../../presentation/screens/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String newChat = '/new-chat';
  static const String groupInfo = '/group-info';
  static const String profile = '/profile';

  static List<GetPage> get pages => [
        GetPage(name: splash, page: () => const SplashScreen()),
        GetPage(name: login, page: () => const LoginScreen()),
        GetPage(name: chatList, page: () => const ChatListScreen()),
        GetPage(
          name: chatRoom,
          page: () => const ChatRoomScreen(),
          binding: BindingsBuilder(() {}),
        ),
        GetPage(name: newChat, page: () => const NewChatScreen()),
        GetPage(
          name: groupInfo,
          page: () => const GroupInfoScreen(),
        ),
        GetPage(name: profile, page: () => const ProfileScreen()),
      ];
}
