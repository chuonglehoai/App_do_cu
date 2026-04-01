import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/ManagePostsScreen.dart';
import '../screens/ProfileScreen.dart';
import '../screens/chat_list_screen.dart'; // Đảm bảo đã import file tin nhắn

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3E8B98),
      unselectedItemColor: Colors.grey[400],
      currentIndex: currentIndex,
      onTap: (index) {
        // Tránh điều hướng lại chính trang đang đứng
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManagePostsScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tin nhắn'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Kho đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Thông báo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
      ],
    );
  }
}