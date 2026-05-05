import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/notification_screen.dart' show NotificationScreen;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/post/manage_posts_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/chat/chat_list_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy userId hiện tại để lắng nghe thông báo tin nhắn
    final String? currentUserId = context.read<UserProvider>().userId;

    return StreamBuilder(
      // Lắng nghe thay đổi tại node list_chat của người dùng hiện tại
      stream: FirebaseDatabase.instance.ref("list_chat/$currentUserId").onValue,
      builder: (context, snapshot) {
        bool hasUnread = false;

        // Kiểm tra nếu có bất kỳ phòng chat nào có unreadCount > 0
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map;
          hasUnread = data.values.any((chat) => (chat['unreadCount'] ?? 0) > 0);
        }

        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3E8B98),
          unselectedItemColor: Colors.grey[400],
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return;

            // Sử dụng pushReplacement để tránh tràn ngăn xếp điều hướng (Navigation Stack)
            Widget nextScreen;
            switch (index) {
              case 0:
                nextScreen = const HomeScreen();
                break;
              case 1:
                nextScreen = const ChatListScreen();
                break;
              case 2:
                nextScreen = const ManagePostsScreen();
                break;
              case 3:
                nextScreen = const NotificationScreen();
              case 4:
                nextScreen = const ProfileScreen();
                break;
              default:
                return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), 
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              // Sử dụng Stack để đè dấu chấm đỏ lên icon tin nhắn
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red, // Màu đỏ nổi bật
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Tin nhắn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), 
              label: 'Kho đồ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), 
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), 
              label: 'Cá nhân',
            ),
          ],
        );
      },
    );
  }
}