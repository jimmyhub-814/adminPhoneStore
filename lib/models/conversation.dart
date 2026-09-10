class Conversation {
  static const userIdField = 'userId'; 
  static const lastMessageField = 'lastMessage';
  static const lastMessageTimeField = 'lastMessageTime';
  static const lastMessageByField = 'lastMessageBy';
  static const unreadCountField = 'unreadCount';

  String userId; 
  String lastMessage;
  int lastMessageTime;
  String lastMessageBy;
  Map<String, dynamic> unreadCount;

  Conversation({
    required this.userId, 
    required this.lastMessage,
    required this.lastMessageBy,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      userIdField: userId, 
      lastMessageField: lastMessage,
      lastMessageByField: lastMessageBy,
      lastMessageTimeField: lastMessageTime,
      unreadCountField: unreadCount,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      userId: map[userIdField] as String, 
      lastMessage: map[lastMessageField] as String,
      lastMessageBy: map[lastMessageByField] as String,
      lastMessageTime: map[lastMessageTimeField] as int,
      unreadCount: map[unreadCountField],
    );
  }
}

enum UnreadCountBy { admin, user }
