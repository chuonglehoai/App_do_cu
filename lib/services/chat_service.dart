import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Hàm tạo hoặc lấy ID phòng chat duy nhất giữa 2 người
  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Sắp xếp theo bảng chữ cái để idUserA-idUserB luôn giống idUserB-idUserA
    return "${ids[0]}_${ids[1]}";
  }

  // Hàm khởi tạo cuộc trò chuyện khi nhấn "Nhắn tin trao đổi"
  Future<String> createChatRoom({
    required String currentUserId,
    required String peerId,
    required String peerName,
    required String peerAvatar,
    required String lastMessage,
  }) async {
    String chatRoomId = _getChatRoomId(currentUserId, peerId);
    
    Map<String, dynamic> updateData = {};

    // 1. Tạo chỉ mục cho người dùng hiện tại
    updateData["list_chat/$currentUserId/$peerId"] = {
      "chatRoomId": chatRoomId,
      "peerName": peerName,
      "peerAvatar": peerAvatar,
      "lastMessage": lastMessage,
      "timestamp": ServerValue.timestamp,
    };

    // 2. Tạo chỉ mục cho đối phương (để họ thấy mình trong danh sách của họ)
    // Lưu ý: Cần lấy thêm thông tin của chính mình để lưu cho đối phương
    updateData["list_chat/$peerId/$currentUserId"] = {
      "chatRoomId": chatRoomId,
      "lastMessage": lastMessage,
      "timestamp": ServerValue.timestamp,
      // Thông tin của bạn nên được lấy từ UserProvider trước khi gọi hàm này
    };

    await _dbRef.update(updateData);
    return chatRoomId;
  }

  // Gửi tin nhắn vào phòng chat
  Future<void> sendMessage(String chatRoomId, String senderId, String receiverId, String text) async {
    final messageData = {
      "senderId": senderId,
      "message": text,
      "timestamp": ServerValue.timestamp,
    };

    Map<String, dynamic> updates = {};
    // 1. Lưu tin nhắn
    String msgId = _dbRef.child("chats/$chatRoomId/messages").push().key!;
    updates["chats/$chatRoomId/messages/$msgId"] = messageData;

    // 2. Cập nhật tin nhắn cuối cho cả 2 người để danh sách chat nhảy lên đầu
    updates["list_chat/$senderId/$receiverId/lastMessage"] = text;
    updates["list_chat/$senderId/$receiverId/timestamp"] = ServerValue.timestamp;
    updates["list_chat/$receiverId/$senderId/lastMessage"] = text;
    updates["list_chat/$receiverId/$senderId/timestamp"] = ServerValue.timestamp;

    await _dbRef.update(updates);
  }
}