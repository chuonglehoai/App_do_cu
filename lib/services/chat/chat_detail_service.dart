import 'package:flutter/material.dart';
import 'package:app_do_cu/services/chat/chat_service.dart';
import 'package:app_do_cu/services/image_helper.dart';
import '../../screens/chat/chat_detail_screen.dart';

abstract class ChatDetailService extends State<ChatDetailScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatService chatService = ChatService();
  final ImageHelper imageHelper = ImageHelper();

  @override
  void initState() {
    super.initState();
    chatService.resetUnreadCount(widget.currentUserId, widget.product.sellerId);
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void handleSendMessage() {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    chatService.sendMessage(
      widget.chatRoomId,
      widget.currentUserId,
      widget.product.sellerId,
      text,
    );

    messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool isImageUrl(String text) {
    return text.startsWith('http') && 
           (text.contains('cloudinary.com') || 
            text.toLowerCase().endsWith('.jpg') || 
            text.toLowerCase().endsWith('.jpeg') || 
            text.toLowerCase().endsWith('.png'));
  }

  Future<void> pickAndSendImage() async {
    String? imageUrl = await imageHelper.pickAndUploadSingle(folder: 'chat_messages');
    if (imageUrl != null) {
      chatService.sendMessage(
        widget.chatRoomId,
        widget.currentUserId,
        widget.product.sellerId,
        imageUrl, 
      );
    }
  }
}