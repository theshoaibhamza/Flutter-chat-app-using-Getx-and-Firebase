import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  // UI state
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool isLoading = false.obs;
  
  // Chat data
  String chatId = "";
  String friendName = "";
  String friendId = "";
  String currentUserId = "";
  
  // Services
  StreamSubscription<QuerySnapshot>? _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    _initializeFromArguments();
  }

  /// Initialize controller from route arguments
  void _initializeFromArguments() {
    final arguments = Get.arguments;
    
    if (arguments is Map<String, dynamic>) {
      // Arguments from mychats screen
      friendName = arguments['name'] ?? "";
      chatId = arguments['chatId'] ?? "";
      friendId = arguments['friendId'] ?? "";
    } else if (arguments is String) {
      // Arguments from friends screen (just friendId)
      friendId = arguments;
      chatId = _generateChatId(currentUserId, friendId);
    } else {
      print('[ChatController] ERROR: Invalid or missing arguments');
    }
    
    print('[ChatController] Initialized with friendId: $friendId, chatId: $chatId, friendName: $friendName');
  }

  /// Generate chat ID from two user IDs
  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ensure consistent ordering
    return ids.join('_');
  }

  /// Open chat with a friend
  Future<void> openChat() async {
    try {
      isLoading.value = true;
      
      // Get friend's name from Firestore if not already provided
      if (friendName.isEmpty) {
        friendName = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
          "users",
          "name",
          friendId,
        ) ?? "Unknown User";
      }

      print('[ChatController] Opening chat with $friendName (ID: $friendId)');
      print('[ChatController] Chat ID: $chatId');

      // Clear existing messages and start listening
      messages.clear();
      await _streamSubscription?.cancel();

      // Listen to messages
      _streamSubscription = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('time', descending: true)
          .snapshots()
          .listen((snapshot) {
        print('[ChatController] Received ${snapshot.docs.length} messages');
        _processMessages(snapshot.docs);
      });

      print('[ChatController] Chat opened successfully');
    } catch (e) {
      print('[ChatController] Error opening chat: $e');
      Get.snackbar(
        'Error',
        'Failed to open chat: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Process incoming messages
  void _processMessages(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> messageList = [];
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Mark message as read if it's from friend
      if (data['senderId'] != currentUserId && data['isRead'] == false) {
        _markMessageAsRead(data['messageId']);
      }
      
      messageList.add(data);
    }
    
    messages.value = messageList;
    print('[ChatController] Updated messages list with ${messageList.length} messages');
  }

  /// Mark message as read
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
      print('[ChatController] Marked message $messageId as read');
    } catch (e) {
      print('[ChatController] Error marking message as read: $e');
    }
  }

  /// Send simple text message
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final messageText = messageController.text.trim();
    messageController.clear();

    try {
      print('[ChatController] Sending message: "$messageText"');
      
      // Create message document
      final messageId = const Uuid().v4();
      final messageData = {
        'messageId': messageId,
        'senderId': currentUserId,
        'message': messageText, // Simple text message, no encryption
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update or create chat document
      final chatDocRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId);
      
      // Check if chat document exists
      final chatDoc = await chatDocRef.get();
      if (!chatDoc.exists) {
        // Create new chat document
        await chatDocRef.set({
          'chatId': chatId,
          'participants': [currentUserId, friendId],
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('[ChatController] Created new chat document');
      } else {
        // Update existing chat document
        await chatDocRef.update({
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
        });
        print('[ChatController] Updated existing chat document');
      }

      print('[ChatController] Message sent successfully');
      
    } catch (e) {
      print('[ChatController] Failed to send message: $e');
      
      // Restore the message text if sending failed
      messageController.text = messageText;
      
      Get.snackbar(
        'Error',
        'Failed to send message: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        duration: Duration(seconds: 5),
      );
    }
  }

  /// Close chat and cleanup
  void closeChat() async {
    messages.clear();
    await _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  @override
  void onClose() {
    messageController.dispose();
    closeChat();
    super.onClose();
  }
}