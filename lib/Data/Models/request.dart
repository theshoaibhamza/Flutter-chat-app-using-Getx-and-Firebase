import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  String requestId;
  String senderId;
  DateTime createdAt;

  Request({
    required this.createdAt,
    required this.senderId,
    required this.requestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'senderId': senderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      requestId: map['requestId'] ?? '',
      senderId: map['senderId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
