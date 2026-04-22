class Message {
  final String? senderId;
  final String? receiverId;
  final String? message;
  final int? timestamp;
  final String? type; // 'text' hoặc 'image'

  Message({
    this.senderId,
    this.receiverId,
    this.message,
    this.timestamp,
    this.type,
  });

  // Chuyển đổi từ Map (Firebase) sang đối tượng Message
  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      senderId: map['senderId'] as String?,
      receiverId: map['receiverId'] as String?,
      message: map['message'] as String?,
      timestamp: map['timestamp'] as int?,
      type: map['type'] as String? ?? 'text',
    );
  }

  // Chuyển đổi từ đối tượng Message sang Map để gửi lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'type': type,
    };
  }
}