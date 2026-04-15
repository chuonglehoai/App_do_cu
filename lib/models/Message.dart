class Message {
  String? messageId;
  String? chatId;
  String? senderId;
  String? senderName;
  String? receiverId;
  String? message;
  String? messageType;
  int? timestamp;
  bool isPinned;
  double? latitude;
  double? longitude;

  Message({
    this.messageId,
    this.chatId,
    this.senderId,
    this.senderName,
    this.receiverId,
    this.message,
    this.messageType = "text",
    this.timestamp,
    this.isPinned = false,
    this.latitude,
    this.longitude,
  });

  // Chuyển từ Firebase Map sang Object Dart
  factory Message.fromMap(Map<dynamic, dynamic> map) {
    print("Debug Message: ${map['message']}");
    return Message(
      messageId: map['messageId'],
      chatId: map['chatId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      receiverId: map['receiverId'],
      message: map['message'],
      messageType: map['messageType'] ?? "text",
      timestamp: map['timestamp'],
      isPinned: map['pinned'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Chuyển từ Object Dart sang Map để đẩy lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp,
      'pinned': isPinned,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}