class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isOnline;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
  });
}