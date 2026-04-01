import 'package:app_do_cu/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:app_do_cu/models/chat_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);

  // Dữ liệu mẫu dựa trên file HTML của bạn
  final List<ChatConversation> _conversations = [
    ChatConversation(
      id: "1",
      name: "Nguyễn Văn An",
      lastMessage: "Mình muốn mua chiếc bàn học gỗ...",
      time: "2 phút",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuBbmBCzPIzgKL8Tfbjg347olZCG5YkEuCnJEc97vQCdfIo62F7KfnsQVbM2OWNyrhEeWesT-BwqAoW4jAf3D1LweV_YbUXRdSQExDDkZM_tQRewy4wEgzhdeh7gr_YaaG2GCOFbucTbXV6GMAa4kIr3K2-xtLzgDLnGUJPBQ5LOWj4XPbqXlyscapb0OFHecLEfmIL5_bme_OxBhwNZs9AewraU-YmzTVNVO7FUuYIpeDU3nJw0RXNYVQRVmQTWEHSQN1kVHAYc7a8",
      isOnline: true,
      unreadCount: 1,
    ),
    ChatConversation(
      id: "2",
      name: "Trần Thị Bảo Ngọc",
      lastMessage: "Bạn ơi, sách này còn không ạ?",
      time: "10:45",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCiEQM1k0M4Lriuz0csXijJhVPuZgtbs4J4iDFr8KSFG6BTmtG5qu0zWot8VeFULxzlnFHQGqjh-O567J5L8_TsBTXfeZGMurNb__3-8bdSCBhM8s_9ZT-rzkVIjTM9guXmVk2Ad0ZR5uYkyrcU52JTQAGLeEnqWOI5XSzlQ_zjo4xOX3P0esawD8T_irwLBTR505u6V8HtLDFAgA6ZYAarDYOTr357Xp5E6-EeHYLOk7iJKO4EbvRBj5aAaQJJj_NeSil3qCZNl50",
    ),
    ChatConversation(
      id: "3",
      name: "Lê Văn Cường",
      lastMessage: "Ok bạn, hẹn gặp ở cổng KTX nhé.",
      time: "Hôm qua",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCMB95bJupvN53M9LvXhIBrMKp0tmo0NBSbucOVnmeAuqm_8fXK1vRtxI2zb6Iv7uJv6rwtKEpgb3h9C3osFHiSzYOMrNSqW7FDW5YDHjFeCKy_Ivt5Zyx67SzZfb_nVhlljdgOs3GtOhoV6a8vpJH3h9ZWU6n_oRbpXwbr_VEgrzRvsRiECvv-5UNRo5RTFK8oDfClvVptNi7Z7f5IybWee5IttznDSGnwznr-6zl9Kq277N0ymHv30sxtOA285YIvEB8rVMnBpqE",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildConversationList(),
            ],
          ),
          
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  // Header phong cách iOS Blur
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
      leading: const Icon(Icons.settings, color: Colors.black54),
      actions: [
        IconButton(
          icon: Icon(Icons.edit_square, color: primaryColor),
          onPressed: () {},
        ),
      ],
    );
  }

  // Thanh tìm kiếm
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm cuộc trò chuyện...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  // Danh sách cuộc trò chuyện
  Widget _buildConversationList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chat = _conversations[index];
          return _buildChatTile(chat);
        },
        childCount: _conversations.length,
      ),
    );
  }

  Widget _buildChatTile(ChatConversation chat) {
    return InkWell(
      onTap: () {
        // Điều hướng sang màn hình Chat chi tiết tại đây
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar với đèn báo Online
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(chat.avatarUrl),
                  backgroundColor: Colors.grey[200],
                ),
                if (chat.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Nội dung tin nhắn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.name,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          color: chat.unreadCount > 0 ? primaryColor : Colors.grey,
                          fontSize: 12,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
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
  }

}