import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../screens/chat_detail_screen.dart';

class ChatNavigationHelper {
  static Future<void> handleChatNavigation({
    required BuildContext context,
    required String? currentUserId,
    required Product product,
    required bool mounted,
  }) async {
    final chatService = ChatService();

    // 1. Kiểm tra an toàn dữ liệu đầu vào
    if (currentUserId == null || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để nhắn tin!")),
      );
      return;
    }

    // Kiểm tra không cho tự nhắn tin cho chính mình
    if (currentUserId == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đây là bài đăng của bạn!")),
      );
      return;
    }

    try {
      // 2. Thực hiện tạo/lấy phòng chat
      String roomId = await chatService.createChatRoom(
        currentUserId: currentUserId,
        peerId: product.sellerId,
        peerName: "Người bán", // Có thể cập nhật lấy từ Firebase sau
        peerAvatar: "",
        lastMessage: "Chào bạn, mình muốn hỏi về sản phẩm: ${product.title}",
      );

      if (!mounted) return;

      // 3. Chuyển trang sau khi hoàn tất
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatRoomId: roomId,
            product: product,
            currentUserId: currentUserId,
          ),
        ),
      );
    } catch (e) {
      print("Lỗi tạo phòng chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể kết nối cuộc trò chuyện: $e")),
        );
      }
    }
  }
}