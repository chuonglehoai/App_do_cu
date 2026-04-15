import 'package:app_do_cu/services/image_helper.dart' show ImageHelper;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/Message.dart'; // Đảm bảo import model Message
import '../services/chat_service.dart';

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

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  // Khai báo helper ở đầu State
  final ImageHelper _imageHelper = ImageHelper();

  @override
  void initState() {
    super.initState();
    // Gọi hàm gửi tin nhắn tự động khi vừa vào màn hình
    _sendInitialProductMessage();
  }

  // Hàm kiểm tra xem một chuỗi có phải là link ảnh không
  bool _isImageUrl(String text) {
    return text.startsWith('http') && 
           (text.contains('cloudinary.com') || 
            text.toLowerCase().endsWith('.jpg') || 
            text.toLowerCase().endsWith('.jpeg') || 
            text.toLowerCase().endsWith('.png'));
  }

  void _sendInitialProductMessage() async {
    // Kiểm tra phòng chat đã có tin nhắn chưa để tránh gửi lặp lại mỗi lần mở
    final snapshot = await FirebaseDatabase.instance
        .ref("chats/${widget.chatRoomId}/messages")
        .limitToFirst(1)
        .get();

    if (!snapshot.exists) {
      String productInfo = "Xin chào bạn, mình muốn trao đổi về sản phẩm này: ${widget.product.title}";
      
      // Gửi tin nhắn văn bản kèm link ảnh sản phẩm (nếu có)
      String finalMessage = productInfo;
      if (widget.product.images.isNotEmpty) {
        finalMessage += "\n${widget.product.images[0]}";
      }

      _chatService.sendMessage(
        widget.chatRoomId,
        widget.currentUserId,
        widget.product.sellerId, // Đảm bảo dùng sellerId từ product
        finalMessage,
      );
    }
  }
  void _handleSendMessage() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      widget.chatRoomId,
      widget.currentUserId,
      widget.product.sellerId,
      text,
    );

    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProductContextBar(),
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
        .child("messages"); // Node messages phải khớp với ChatService

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
          
          // Xử lý an toàn cho cả Map và List (Phòng lỗi Cast của Firebase)
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
          // Sắp xếp tin nhắn
          messages.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            bool isMe = msg.senderId == widget.currentUserId;
            
            // Quan trọng: msg.message là nội dung tin nhắn từ model Message.dart
            return _buildChatBubble(
              msg.message ?? "", // Đảm bảo lấy đúng field 'message'
              isMe, 
              msg.timestamp ?? 0
            );
          },
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isMe, int timestamp) {
    String time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    bool isImage = _isImageUrl(text);

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 200,  // Chiều rộng tối đa của ảnh
              maxHeight: 300, // Chiều cao tối đa của ảnh (để tránh ảnh dọc quá dài)
              minWidth: 100,  // Chiều rộng tối thiểu
            ),
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
                  child: Image.network(
                    text,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: const CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.beVietnamPro(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            time,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image, color: primaryColor),
              onPressed: () async {
                // 1. Chỉ 1 dòng duy nhất để lấy URL ảnh từ Cloudinary
                String? imageUrl = await _imageHelper.pickAndUploadSingle(folder: 'chat_messages');

                if (imageUrl != null) {
                  // 2. Gửi URL này vào Firebase Chat
                  _chatService.sendMessage(
                    widget.chatRoomId,
                    widget.currentUserId,
                    widget.product.sellerId,
                    imageUrl, 
                  );
                }
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...", 
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _handleSendMessage,
              ),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: FutureBuilder<DataSnapshot>(
        // Truy vấn thông tin người bán từ node users dựa trên id
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
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                    ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) 
                    ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.beVietnamPro(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductContextBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 45, height: 45,
              color: Colors.grey[200],
              child: widget.product.images.isNotEmpty 
                ? Image.network(widget.product.images[0], fit: BoxFit.cover)
                : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.title, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text("${widget.product.price} VNĐ", 
                  style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}