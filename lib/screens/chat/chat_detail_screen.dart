import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/Message.dart'; 
import '../../widgets/full_screen_image_viewer.dart';
import '../../services/chat/chat_detail_service.dart'; // Import controller

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final Product product;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.product,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ChatDetailService {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final Query chatQuery = FirebaseDatabase.instance
        .ref("chats")
        .child(widget.chatRoomId)
        .child("messages");

    return StreamBuilder(
      stream: chatQuery.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải tin nhắn"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Message> messages = [];
        if (snapshot.data!.snapshot.exists) {
          final dynamic data = snapshot.data!.snapshot.value;
          
          if (data is Map) {
            data.forEach((key, value) {
              messages.add(Message.fromMap(Map<dynamic, dynamic>.from(value)));
            });
          } else if (data is List) {
            for (var value in data) {
              if (value != null) {
                messages.add(Message.fromMap(Map<dynamic, dynamic>.from(value)));
              }
            }
          }
          messages.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            bool isMe = msg.senderId == widget.currentUserId;
            return _buildChatBubble(msg.message ?? "", isMe, msg.timestamp ?? 0);
          },
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isMe, int timestamp) {
    String time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    bool isImage = isImageUrl(text);

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isImage ? Colors.transparent : (isMe ? primaryColor : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: isImage 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => FullScreenImageViewer.open(context, [text]),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200, minWidth: 100),
                      color: Colors.grey[200],
                      child: Image.network(
                        text,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200, height: 100,
                            padding: const EdgeInsets.all(20),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : Text(text, style: GoogleFonts.beVietnamPro(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.image, color: primaryColor), onPressed: pickAndSendImage),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF0F2F2), borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  onSubmitted: (_) => handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: handleSendMessage),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      titleSpacing: 0,
      title: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref("users").child(widget.product.sellerId).get(),
        builder: (context, snapshot) {
          String name = "Đang tải...";
          String? avatarUrl;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = Map<dynamic, dynamic>.from(snapshot.data!.value as Map);
            name = data['fullName'] ?? "Người dùng";
            avatarUrl = data['avatarUrl'];
          }
          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
              ),
              const SizedBox(width: 10),
              Text(name, style: GoogleFonts.beVietnamPro(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }

  
}