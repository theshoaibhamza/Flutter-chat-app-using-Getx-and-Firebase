class Message {
  String messageId;
  Map<String, String> securedMessage;
  DateTime time;
  String senderId;
  bool isRead;

  Message({
    required this.messageId,
    required this.securedMessage,
    required this.time,
    required this.senderId,
    required this.isRead,
  });

  /// Convert Message object to Map (for Firestore/JSON)
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'message': securedMessage,
      'time': time,
      'senderId': senderId,
      'isRead': isRead,
    };
  }

  /// Create Message object from Map (Firestore/JSON)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'] ?? '',
      securedMessage: Map<String, String>.from(map['message'] ?? {}),
      time: map['time'] is DateTime 
          ? map['time'] 
          : DateTime.now(), // Handle Firestore Timestamp
      senderId: map['senderId'] ?? '',
      isRead: map['isRead'] ?? false,
    );
  }
}
