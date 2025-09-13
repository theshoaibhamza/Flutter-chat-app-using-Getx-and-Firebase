import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String email;
  String name;
  String publicKey;
  DateTime createdAt;
  DateTime lastLogin;

  static UserModel? _instance;

  // Private constructor
  UserModel._({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.lastLogin,
    required this.publicKey,
  });

  // Factory to access the singleton
  static UserModel get instance {
    if (_instance == null) {
      return UserModel._(
        id: "",
        publicKey: "",
        email: "",
        name: "",
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
    }
    return _instance!;
  }

  // Call this after login to initialize the singleton
  static void initialize(Map<String, dynamic> map) {
    _instance = UserModel._(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      publicKey: map['publicKey'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'publicKey': publicKey,
    };
  }
}
