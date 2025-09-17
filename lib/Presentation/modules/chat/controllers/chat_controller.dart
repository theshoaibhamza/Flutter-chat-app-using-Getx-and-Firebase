import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:internee_app3/app/Services/encryption_service.dart';
import 'package:uuid/uuid.dart';
import 'package:cryptography/cryptography.dart';

class ChatController extends GetxController {
  // UI state
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> decryptedMessages = <String, String>{}.obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool isLoading = false.obs;
  
  // Chat data
  String chatId = "";
  String friendName = "";
  String friendId = "";
  String friendPublicKey = "";
  String currentUserId = "";
  bool isGroupChat = false;
  SecretKey? groupKey; // For group encryption
  List<String> groupMemberIds = []; // List of group member IDs 
  
  // Services
  final EncryptionService _encryptionService = EncryptionService();
  StreamSubscription<QuerySnapshot>? _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    _initializeFromArguments();
    _initializeEncryption();
  }

  /// Initialize encryption service
  Future<void> _initializeEncryption() async {
    try {
      await _encryptionService.initialize();
      print('[ChatController] Encryption service initialized');
    } catch (e) {
      print('[ChatController] Failed to initialize encryption: $e');
    }
  }

  /// Initialize controller from route arguments
  void _initializeFromArguments() {
    final arguments = Get.arguments;
    
    if (arguments is Map<String, dynamic>) {
      // Arguments from mychats screen
      friendName = arguments['name'] ?? "";
      chatId = arguments['chatId'] ?? "";
      friendId = arguments['friendId'] ?? "";
      isGroupChat = arguments['isGroup'] ?? false;
    } else if (arguments is String) {
      // Arguments from friends screen (just friendId)
      friendId = arguments;
      chatId = _generateChatId(currentUserId, friendId);
      isGroupChat = false;
    } else {
      print('[ChatController] ERROR: Invalid or missing arguments');
    }
    
    print('[ChatController] Initialized with friendId: $friendId, chatId: $chatId, friendName: $friendName, isGroup: $isGroupChat');
  }

  /// Generate chat ID from two user IDs
  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ensure consistent ordering
    return ids.join('_');
  }

  /// Open chat with a friend or group
  Future<void> openChat() async {
    try {
      isLoading.value = true;
      
      // Validate required parameters
      if (chatId.isEmpty) {
        throw Exception('Chat ID is empty');
      }
      
      print('[ChatController] Opening chat - ID: $chatId, Name: $friendName, FriendID: $friendId, IsGroup: $isGroupChat');
      
      // Handle group chat vs individual chat differently
      if (isGroupChat) {
        // For group chats, friendName should already be set from arguments
        if (friendName.isEmpty) {
          friendName = "Group Chat";
        }
        
        // Load group members and set up group encryption
        await _loadGroupEncryption();
        
        print('[ChatController] Opening group chat: $friendName');
      } else {
        // For individual chats, get friend's data if not already provided
        if (friendId.isEmpty) {
          throw Exception('Friend ID is empty for individual chat');
        }
        
        if (friendName.isEmpty) {
          friendName = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
            "users",
            "name",
            friendId,
          ) ?? "Unknown User";
        }

        // Get friend's public key from Firestore for encryption
        friendPublicKey = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
          "users",
          "publicKey",
          friendId,
        ) ?? "";

        if (friendPublicKey.isEmpty) {
          print('[ChatController] WARNING: Friend has no public key, encryption disabled');
        } else {
          // Test encryption with friend's key
          final testPassed = await _encryptionService.testEncryption(friendPublicKey);
          print('[ChatController] Encryption test ${testPassed ? 'PASSED' : 'FAILED'}');
        }
        
        print('[ChatController] Opening individual chat with $friendName (ID: $friendId)');
      }

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
        'Failed to open chat: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load group encryption data for group chats
  Future<void> _loadGroupEncryption() async {
    print('[ChatController] Loading group encryption for chat: $chatId');
    
    try {
      // First, try to get the group key from local storage
      groupKey = await _encryptionService.getStoredGroupKey(chatId);
      
      if (groupKey != null) {
        print('[ChatController] Group key found in local storage');
      } else {
        print('[ChatController] No group key in local storage, fetching from Firestore...');
        await _fetchGroupKeyFromFirestore();
      }
      
      // Load group member IDs
      await _loadGroupMembers();
      
    } catch (e) {
      print('[ChatController] Error loading group encryption: $e');
      // Group encryption failed, but we can still continue with plain text
    }
  }

  /// Fetch encrypted group key from Firestore and decrypt it
  Future<void> _fetchGroupKeyFromFirestore() async {
    try {
      // Get the chat document to find the group creator
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        throw Exception('Chat document not found');
      }
      
      final chatData = chatDoc.data()!;
      final createdBy = chatData['createdBy'] as String?;
      
      if (createdBy == null) {
        throw Exception('Chat creator not found');
      }
      
      // Get the encrypted group key for current user
      final groupKeyDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('groupKeys')
          .doc(currentUserId)
          .get();
      
      if (!groupKeyDoc.exists) {
        print('[ChatController] No group key found for current user in Firestore');
        return;
      }
      
      final encryptedGroupKeyData = groupKeyDoc.data()!;
      final encryptedGroupKey = Map<String, String>.from(encryptedGroupKeyData);
      
      // Get the group creator's public key to decrypt the group key
      final creatorPublicKey = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
        "users",
        "publicKey",
        createdBy,
      );
      
      if (creatorPublicKey == null || creatorPublicKey.isEmpty) {
        throw Exception('Group creator public key not found');
      }
      
      // Decrypt the group key
      groupKey = await _encryptionService.decryptGroupKey(
        encryptedGroupKey: encryptedGroupKey,
        senderPublicKeyBase64: creatorPublicKey,
      );
      
      if (groupKey != null) {
        // Store the group key locally for future use
        await _encryptionService.storeGroupKey(
          chatId: chatId,
          groupKey: groupKey!,
        );
        print('[ChatController] Group key decrypted and stored successfully');
      }
      
    } catch (e) {
      print('[ChatController] Error fetching group key from Firestore: $e');
    }
  }

  /// Load group member IDs from Firestore
  Future<void> _loadGroupMembers() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        groupMemberIds = List<String>.from(chatData['users'] ?? []);
        print('[ChatController] Loaded ${groupMemberIds.length} group members');
      }
    } catch (e) {
      print('[ChatController] Error loading group members: $e');
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

      // Decrypt message if it's encrypted
      if (data['message'] is Map) {
        _decryptMessage(data);
      }
      
      messageList.add(data);
    }
    
    messages.value = messageList;
    print('[ChatController] Updated messages list with ${messageList.length} messages');
  }

  /// Decrypt incoming message
  Future<void> _decryptMessage(Map<String, dynamic> message) async {
    final messageId = message['messageId'] as String;
    final senderId = message['senderId'] as String;
    
    print('[ChatController] Decrypting message $messageId from sender $senderId');
    print('[ChatController] Current user ID: $currentUserId');
    
    try {
      // If this is our own message and we have plaintext stored, use it
      if (senderId == currentUserId && message.containsKey('plaintext')) {
        decryptedMessages[messageId] = message['plaintext'] as String;
        print('[ChatController] Using stored plaintext for own message: $messageId');
        return;
      }

      // Handle group chat decryption
      if (isGroupChat) {
        if (groupKey == null) {
          decryptedMessages[messageId] = '[Group encryption key not available]';
          print('[ChatController] No group key available for decryption');
          return;
        }

        // Extract encrypted data
        final encryptedData = Map<String, String>.from(
          (message['message'] as Map).cast<String, String>()
        );
        
        print('[ChatController] Decrypting group message with group key');
        print('[ChatController] Encrypted data keys: ${encryptedData.keys.toList()}');

        // Decrypt using group key
        final decryptedText = await _encryptionService.decryptGroupMessage(
          encryptedData: encryptedData,
          groupKey: groupKey!,
        );

        decryptedMessages[messageId] = decryptedText;
        print('[ChatController] Successfully decrypted group message: $messageId');
        return;
      }

      // Handle individual chat decryption
      if (senderId != currentUserId) {
        if (friendPublicKey.isEmpty) {
          decryptedMessages[messageId] = '[Friend encryption key not available]';
          print('[ChatController] No friend public key available for decryption');
          return;
        }

        // Extract encrypted data
        final encryptedData = Map<String, String>.from(
          (message['message'] as Map).cast<String, String>()
        );
        
        print('[ChatController] Encrypted data keys: ${encryptedData.keys.toList()}');
        print('[ChatController] Using friend public key: ${friendPublicKey.substring(0, 20)}...');

        // Decrypt using friend's public key (creates shared secret with our private key)
        final decryptedText = await _encryptionService.decryptMessage(
          encryptedData: encryptedData,
          senderPublicKeyBase64: friendPublicKey,
        );

        decryptedMessages[messageId] = decryptedText;
        print('[ChatController] Successfully decrypted friend message: $messageId');
      } else {
        // This is our own message but no plaintext stored - shouldn't happen with new messages
        decryptedMessages[messageId] = '[Cannot decrypt own message - plaintext not stored]';
        print('[ChatController] Cannot decrypt own message without stored plaintext: $messageId');
      }
      
    } catch (e) {
      print('[ChatController] Failed to decrypt message $messageId: $e');
      
      // Handle different types of decryption errors
      if (e.toString().contains('SecretBoxAuthenticationError') || 
          e.toString().contains('MAC')) {
        decryptedMessages[messageId] = '[Old encrypted message - cannot decrypt]';
        print('[ChatController] MAC error detected - likely old encrypted message format');
      } else {
        decryptedMessages[messageId] = '[Failed to decrypt message]';
      }
    }
  }

  /// Get decrypted message for UI display
  String getDecryptedMessage(String messageId, dynamic messageContent) {
    // If message is already plain text, return it
    if (messageContent is String) {
      return messageContent;
    }
    
    // If message is encrypted, return decrypted version or status
    return decryptedMessages[messageId] ?? '[Decrypting...]';
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

  /// Send message (encrypted for individual chats, plain text for group chats)
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final messageText = messageController.text.trim();
    messageController.clear();

    try {
      print('[ChatController] Sending message: "$messageText"');
      
      // Create message document
      final messageId = const Uuid().v4();
      Map<String, dynamic> messageData;

      // For group chats, always send plain text (encryption not practical for multiple recipients)
      if (isGroupChat) {
        messageData = {
          'messageId': messageId,
          'senderId': currentUserId,
          'message': messageText, // Plain text message
          'time': FieldValue.serverTimestamp(),
          'isRead': false,
        };
        print('[ChatController] Sending plain text message to group chat');
      } else {
        // For individual chats, check if encryption is available
        if (friendPublicKey.isNotEmpty && await _encryptionService.hasKeys()) {
          // Send encrypted message
          final encryptedData = await _encryptionService.encryptMessage(
            plaintext: messageText,
            friendPublicKeyBase64: friendPublicKey,
          );

          messageData = {
            'messageId': messageId,
            'senderId': currentUserId,
            'message': encryptedData, // Encrypted message
            'plaintext': messageText, // Store plaintext for sender's reference
            'time': FieldValue.serverTimestamp(),
            'isRead': false,
          };
          print('[ChatController] Message encrypted and ready to send');
        } else {
          // Send plain text message (fallback)
          messageData = {
            'messageId': messageId,
            'senderId': currentUserId,
            'message': messageText, // Plain text message
            'time': FieldValue.serverTimestamp(),
            'isRead': false,
          };
          print('[ChatController] Sending as plain text (encryption not available)');
        }
      }

      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat document
      await _updateChatDocument(messageText);

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

  /// Update or create chat document
  Future<void> _updateChatDocument(String lastMessage) async {
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId);
    
    // Check if chat document exists
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      // Create new chat document
      if (isGroupChat) {
        // For group chats, we don't create new chat documents here
        // They should already exist from group creation
        print('[ChatController] Group chat document should already exist');
      } else {
        // Create individual chat document
        await chatDocRef.set({
          'chatId': chatId,
          'participants': [currentUserId, friendId],
          'users': [currentUserId, friendId], // For compatibility
          'lastMessage': lastMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'isGroup': false,
        });
        print('[ChatController] Created new individual chat document');
      }
    } else {
      // Update existing chat document
      await chatDocRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
      });
      print('[ChatController] Updated existing chat document');
    }
  }

  /// Close chat and cleanup
  void closeChat() async {
    messages.clear();
    decryptedMessages.clear();
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