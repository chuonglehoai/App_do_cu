import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/post/manage_posts_screen.dart';
import 'package:app_do_cu/widgets/custom_bottom_nav.dart' show CustomBottomNav;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = context.read<UserProvider>().userId ?? "";
    final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("notifications/$userId");

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Thông báo', 
          style: GoogleFonts.beVietnamPro(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF3E8B98)),
            onPressed: () => _dbRef.update({"isRead": true}), // Đánh dấu đọc tất cả
          )
        ],
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          List<Map<dynamic, dynamic>> notifications = [];
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            data.forEach((key, value) {
              notifications.add({...value, "id": key});
            });
            // Sắp xếp thông báo mới nhất lên đầu
            notifications.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
          }

          if (notifications.isEmpty) {
            return const Center(child: Text("Không có thông báo nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationItem(context, item, _dbRef);
            },
          );
          
        },
        
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map item, DatabaseReference ref) {
    bool isRead = item['isRead'] ?? false;
    String type = item['type'] ?? "";

    return GestureDetector(
      onTap: () {
        // 1. Đánh dấu đã đọc trên Firebase
        ref.child(item['id']).update({"isRead": true});
        
        // 2. Điều hướng sang ManagePostsScreen với tabIndex tương ứng
        // Bạn cần chỉnh sửa ManagePostsScreen để nhận tham số initialIndex
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ManagePostsScreen(initialTabIndex: item['tabIndex'] ?? 0)
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFFFFD),
          borderRadius: BorderRadius.circular(12),
          border: isRead ? null : Border.all(color: const Color(0xFF3E8B98).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['title'] ?? "", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getTitleColor(type))),
                      Text(_formatTime(item['timestamp']), 
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item['content'] ?? "", 
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                  if (type == "post_refused")
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Chỉnh sửa ngay →", 
                        style: TextStyle(color: const Color(0xFF3E8B98), fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    if (type == "post_approved") {
      icon = Icons.check_circle;
      bgColor = Colors.green.shade50;
      iconColor = Colors.green;
    } else if (type == "post_refused") {
      icon = Icons.cancel;
      bgColor = Colors.red.shade50;
      iconColor = Colors.red;
    } else {
      icon = Icons.notifications;
      bgColor = Colors.blue.shade50;
      iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  Color _getTitleColor(String type) {
    if (type == "post_approved") return Colors.green.shade700;
    if (type == "post_refused") return Colors.red.shade700;
    return Colors.black87;
  }

  String _formatTime(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm dd/MM').format(date);
  }
}