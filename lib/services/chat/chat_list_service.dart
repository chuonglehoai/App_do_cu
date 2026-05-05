import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import 'chat_service.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/chat/chat_list_screen.dart';

abstract class ChatListService extends State<ChatListScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);

  String formatLastMessage(String msg) {
    if (msg.contains('cloudinary.com')) return "[Hình ảnh]";
    return msg;
  }

  String formatTimestamp(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM').format(date);
  }

  void navigateToChatDetail(String peerId, String currentUserId) {
    ChatService().resetUnreadCount(currentUserId, peerId);
    List<String> ids = [currentUserId, peerId];
    ids.sort();
    String chatRoomId = ids.join("_");

    Product placeholderProduct = Product(
      id: "0",
      title: "Sản phẩm đang thảo luận",
      price: 0.0,
      description: "",
      address: "",
      sellerId: peerId,
      images: [],
      category: "",
      createdAt: "",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatRoomId: chatRoomId,
          currentUserId: currentUserId,
          product: placeholderProduct,
        ),
      ),
    );
  }
}