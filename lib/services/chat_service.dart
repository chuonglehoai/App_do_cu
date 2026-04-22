import 'package:firebase_database/firebase_database.dart';

class ChatService {
  // Khởi tạo tham chiếu Database dùng chung cho cả class
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 1. Hàm gửi tin nhắn và cập nhật thông báo chưa đọc
  Future<void> sendMessage(
    String chatRoomId, 
    String senderId, 
    String receiverId, 
    String text
  ) async {
    final messageData = {
      "senderId": senderId,
      "message": text,
      "timestamp": ServerValue.timestamp,
    };

    // Tạo một Map để thực hiện cập nhật đồng thời (Atomic Update)
    Map<String, dynamic> updates = {};

    // Gửi tin nhắn vào node chats
    // Lưu ý: push().key để lấy ID tin nhắn mới mà không cần đợi gửi xong
    String? newMessageKey = _dbRef.child("chats/$chatRoomId/messages").push().key;
    updates["chats/$chatRoomId/messages/$newMessageKey"] = messageData;

    // Cập nhật cho người gửi (unreadCount giữ nguyên hoặc về 0)
    updates["list_chat/$senderId/$receiverId/lastMessage"] = text;
    updates["list_chat/$senderId/$receiverId/timestamp"] = ServerValue.timestamp;
    updates["list_chat/$senderId/$receiverId/chatRoomId"] = chatRoomId;

    // Cập nhật cho người nhận (Tăng unreadCount thêm 1)
    updates["list_chat/$receiverId/$senderId/lastMessage"] = text;
    updates["list_chat/$receiverId/$senderId/timestamp"] = ServerValue.timestamp;
    updates["list_chat/$receiverId/$senderId/chatRoomId"] = chatRoomId;
    updates["list_chat/$receiverId/$senderId/unreadCount"] = ServerValue.increment(1);
    
    try {
      await _dbRef.update(updates);
    } catch (e) {
      print("Lỗi khi gửi tin nhắn: $e");
    }
  }

  // 2. Hàm reset tin nhắn chưa đọc khi user mở phòng chat
  Future<void> resetUnreadCount(String currentUserId, String peerId) async {
    try {
      // Trỏ đúng vào node unreadCount của user hiện tại với đối phương
      await _dbRef.child("list_chat/$currentUserId/$peerId/unreadCount").set(0);
    } catch (e) {
      print("Lỗi khi reset unreadCount: $e");
    }
  }
}