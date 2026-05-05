import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/product_model.dart';
import '../../screens/chat/chat_detail_screen.dart';

class ChatNavigationHelper {
  static Future<void> handleChatNavigation({
    required BuildContext context,
    required String? currentUserId,
    required Product product,
    required bool mounted,
  }) async {
    if (currentUserId == null) return;

    // 1. Tạo ChatRoomId duy nhất giữa người mua và người bán
    List<String> ids = [currentUserId, product.sellerId];
    ids.sort();
    String chatRoomId = ids.join("_");

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    try {
      // 2. Kiểm tra xem phòng chat này đã có tin nhắn nào chưa
      final chatSnapshot = await dbRef
          .child("chats")
          .child(chatRoomId)
          .child("messages")
          .limitToFirst(1)
          .get();

      // 3. Nếu chưa có tin nhắn (Lần đầu nhắn tin về sản phẩm này)
      if (!chatSnapshot.exists) {
        // Gửi tin nhắn chữ
        String welcomeText = "Xin chào, mình muốn trao đổi về sản phẩm: ${product.title}";
        
        // Gửi tin nhắn chữ vào node messages
        await dbRef.child("chats/$chatRoomId/messages").push().set({
          "senderId": currentUserId,
          "message": welcomeText,
          "timestamp": ServerValue.timestamp,
        });

        // Gửi tin nhắn ảnh sản phẩm (nếu có) để người bán dễ nhận diện
        if (product.images.isNotEmpty) {
          await dbRef.child("chats/$chatRoomId/messages").push().set({
            "senderId": currentUserId,
            "message": product.images[0], // Gửi link ảnh gốc Cloudinary
            "timestamp": ServerValue.timestamp,
          });
        }

        // Cập nhật danh sách chat (list_chat) cho cả 2 người để hiện ở màn hình danh sách
        Map<String, dynamic> listChatUpdate = {};
        listChatUpdate["list_chat/$currentUserId/${product.sellerId}"] = {
          "chatRoomId": chatRoomId,
          "lastMessage": welcomeText,
          "timestamp": ServerValue.timestamp,
        };
        listChatUpdate["list_chat/${product.sellerId}/$currentUserId"] = {
          "chatRoomId": chatRoomId,
          "lastMessage": welcomeText,
          "timestamp": ServerValue.timestamp,
        };

        await dbRef.update(listChatUpdate);
      }

      // 4. Chuyển hướng sang màn hình ChatDetailScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chatRoomId,
              product: product,
              currentUserId: currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Lỗi chuyển hướng Chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể kết nối với người bán")),
        );
      }
    }
  }
}