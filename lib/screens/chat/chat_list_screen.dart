import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/widgets/custom_bottom_nav.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../services/chat/chat_list_service.dart'; // Import controller

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ChatListService {
  @override
  Widget build(BuildContext context) {
    final String? currentUserId = context.read<UserProvider>().userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: currentUserId == null
          ? const Center(child: Text("Vui lòng đăng nhập"))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildConversationList(currentUserId),
              ],
            ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Text(
        'Tin nhắn',
        style: GoogleFonts.beVietnamPro(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildConversationList(String currentUserId) {
    final query = FirebaseDatabase.instance.ref("list_chat").child(currentUserId);

    return StreamBuilder(
      stream: query.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SliverToBoxAdapter(child: Center(child: Text("Lỗi tải dữ liệu")));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SliverToBoxAdapter(child: Center(child: Text("Chưa có tin nhắn nào")));
        }

        Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
        List<MapEntry<dynamic, dynamic>> items = data.entries.toList();

        items.sort((a, b) => (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              String peerId = items[index].key;
              var chatData = items[index].value;
              return _buildChatTile(peerId, chatData, currentUserId);
            },
            childCount: items.length,
          ),
        );
      },
    );
  }

  Widget _buildChatTile(String peerId, dynamic chatData, String currentUserId) {
    int unreadCount = chatData['unreadCount'] ?? 0;
    return FutureBuilder(
      future: FirebaseDatabase.instance.ref("users").child(peerId).get(),
      builder: (context, userSnapshot) {
        String name = "Đang tải...";
        String avatar = "";

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.value as Map;
          name = userData['fullName'] ?? "Người dùng";
          avatar = userData['avatarUrl'] ?? "";
        }

        return InkWell(
          onTap: () => navigateToChatDetail(peerId, currentUserId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600)),
                          Text(formatTimestamp(chatData['timestamp']), 
                              style: TextStyle(color: unreadCount > 0 ? primaryColor : Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatLastMessage(chatData['lastMessage'] ?? ""),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                              child: Text(
                                unreadCount > 9 ? "9+" : unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}