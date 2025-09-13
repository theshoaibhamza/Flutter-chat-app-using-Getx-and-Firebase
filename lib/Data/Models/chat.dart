class Chat {
  String chatId;
  String createdBy;
  String time;
  List<String> users;
  String lastMessageId;
  Map<String, dynamic> unRead;

  Chat({
    required this.chatId,

    required this.createdBy,
    required this.time,
    required this.users,
    required this.lastMessageId,
    required this.unRead,
  });

  /// Convert Chat object to Map
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'createdBy': createdBy,
      'time': time,
      'users': users,
      'lastMessageId': lastMessageId,
      'unRead': unRead,
    };
  }

  /// Create Chat object from Map
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      time: map['time'] ?? '',
      users: List<String>.from(map['users'] ?? []),
      unRead: Map<String, dynamic>.from(map['unRead'] ?? {}),
      lastMessageId: map['lastMessageId'] ?? '',
    );
  }
}
