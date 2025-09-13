// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:internee_app3/Data/Models/message.dart';
// import 'package:internee_app3/app/Config/firebase_messaging.dart';
// import 'package:internee_app3/app/Services/encryption_old.dart';

// import 'package:internee_app3/app/Services/firebase_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class ChatController extends GetxController {
//   final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
//   final RxMap<String, String> decryptedMessages = <String, String>{}.obs;
//   StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;
//   String currentUserId = "";
//   final TextEditingController messageController = TextEditingController();
//   late String chatId; // receive it as arguments
//   late String friendName; // receive it as arguments
//   late String friendId; // receive it as arguments
//   String friendPublicKey = ""; // receive it as arguments
//   String? senderName = "";
//   RxInt count = 0.obs;
//   String plainText = "";

//   Future<void> openChat() async {
//     // Get friend's public key
//     friendPublicKey =
//         await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//           "users",
//           "publicKey",
//           friendId,
//         ) ??
//         "NULL";

//     print("Friend's Public Key: $friendPublicKey");
    
//     // Check if we have our own private key
//     SharedPreferences _prefs = await SharedPreferences.getInstance();
//     String myPrivateKey = await _prefs.getString("private-key") ?? "";
//     String myPublicKey = await _prefs.getString("public-key") ?? "";
    
//     print("My Private Key exists: ${myPrivateKey.isNotEmpty}");
//     print("My Public Key: $myPublicKey");
    
//     if (myPrivateKey.isEmpty) {
//       print("WARNING: No private key found! Generating new keys...");
//       await storePrivateKey();
//       // Update user's public key in Firestore
//       String newPublicKey = await _prefs.getString("public-key") ?? "";
//       if (newPublicKey.isNotEmpty) {
//         await FirebaseProvider.updateMainCollectionDocumentField(
//           'users',
//           currentUserId,
//           'publicKey',
//           newPublicKey,
//         );
//         print("Updated user's public key in Firestore: $newPublicKey");
//       }
//     }

//     senderName =
//         await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//           "users",
//           "name",
//           currentUserId,
//         ) ??
//         "NULL";

//     // here i need to empty the messages list first
//     messages.clear();

//     await _streamSubscription?.cancel();

//     // now i have to fetch the chat from firebase of specific friend using chatID

//     // store the chat in messages list to reflect in UI
//     _streamSubscription =
//         await FirebaseProvider.fetchSubCollection(
//           'chats',
//           chatId,
//           'messages',
//           orderByField: 'time',
//           descending: true,
//         ).listen((messageList) async {
//           for (var message in messageList) {
//             if (await FirebaseAuth.instance.currentUser!.uid !=
//                 message['senderId']) {
//               print("Current : " + currentUserId);
//               print("SenderId : " + message['senderId']);

//               if (message['isRead'] == false) {
//                 final docRef = FirebaseFirestore.instance
//                     .collection('chats')
//                     .doc(chatId)
//                     .collection('messages')
//                     .doc(message['messageId']);

//                 docRef.update({"isRead": true});
//               }
//             }
            
//             // Decrypt the message if it has encrypted content
//             if (message['message'] != null) {
//               await decryptAndStoreMessage(message);
//             }
//           }

//           messages.value = List<Map<String, dynamic>>.from(messageList);

//           countUnReadMessages();
//           await FirebaseProvider.updateMainCollectionDocumentMapOneField(
//             "chats",
//             chatId,
//             "unRead",
//             currentUserId,
//             0.toString(),
//           );
//         });
//   }

//   Future<void> decryptAndStoreMessage(Map<String, dynamic> message) async {
//     try {
//       if (message['message'] == null) {
//         print("No encrypted message data found");
//         return;
//       }
      
//       Map<String, dynamic> encryptedMessage = Map<String, dynamic>.from(message['message']);
      
//       print("=== DECRYPTION DEBUG START ===");
//       print("Encrypted message data: $encryptedMessage");
//       print("Available keys in encrypted message: ${encryptedMessage.keys.toList()}");
//       print("Message ID: ${message['messageId']}");
//       print("Sender ID: ${message['senderId']}");
//       print("Current User ID: $currentUserId");
      
//       SharedPreferences _prefs = await SharedPreferences.getInstance();
//       String myPrivateKey = await _prefs.getString("private-key") ?? "";
      
//       if (myPrivateKey.isEmpty) {
//         print("ERROR: Missing my private key");
//         decryptedMessages[message['messageId']] = "[Missing private key]";
//         return;
//       }

//       // Decode and validate key lengths
//       Uint8List privateKey;
//       Uint8List senderPublicKey;
//       String? senderPublicKeyBase64;
      
//       try {
//         privateKey = base64Decode(myPrivateKey);
        
//         // For decryption, we need the sender's public key
//         String senderId = message['senderId'];
//         print("Getting public key for sender: $senderId");
        
//         senderPublicKeyBase64 = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//           "users",
//           "publicKey", 
//           senderId,
//         );
        
//         print("Sender's public key from Firestore: $senderPublicKeyBase64");
        
//         if (senderPublicKeyBase64 == null || senderPublicKeyBase64.isEmpty || senderPublicKeyBase64 == "NULL") {
//           print("ERROR: Cannot get sender's public key for decryption");
//           decryptedMessages[message['messageId']] = "[Sender's encryption key not found]";
//           return;
//         }
        
//         senderPublicKey = base64Decode(senderPublicKeyBase64);
        
//         // Validate key lengths
//         if (privateKey.length != 32) {
//           print("ERROR: Invalid private key length: ${privateKey.length} bytes, expected 32");
//           decryptedMessages[message['messageId']] = "[Invalid private key length]";
//           return;
//         }
        
//         if (senderPublicKey.length != 32) {
//           print("ERROR: Invalid sender public key length: ${senderPublicKey.length} bytes, expected 32");
//           decryptedMessages[message['messageId']] = "[Invalid sender public key length]";
//           return;
//         }
//       } catch (e) {
//         print("ERROR: Error decoding keys: $e");
//         decryptedMessages[message['messageId']] = "[Key decoding error: $e]";
//         return;
//       }

//       // Generate shared secret using MY private key + SENDER's public key
//       print("=== KEY COMPARISON DEBUG ===");
//       print("Friend's public key used for encryption: $friendPublicKey");
//       print("Sender's public key retrieved for decryption: $senderPublicKeyBase64");
//       print("Are they the same? ${friendPublicKey == senderPublicKeyBase64}");
      
//       if (friendPublicKey != senderPublicKeyBase64) {
//         print("ERROR: Key mismatch detected!");
//         print("This explains the MAC authentication failure.");
//         print("The message was encrypted with a different public key than we're using for decryption.");
        
//         // Try using the same key that was used for encryption
//         print("Attempting decryption with the encryption key instead...");
//         try {
//           Uint8List friendPublicKeyBytes = base64Decode(friendPublicKey);
          
//           if (friendPublicKeyBytes.length == 32) {
//             SecretKey alternativeSharedSecret = await generateSharedSecretKey(
//               myPrivateKeySeed: privateKey,
//               receiverPublicKeyBytes: friendPublicKeyBytes,
//             );
            
//             String alternativeDecrypted = await decryptMessage(
//               aesKey: alternativeSharedSecret,
//               ciphertextB64: encryptedMessage['ciphertext'] ?? '',
//               nonceB64: encryptedMessage['nonce'] ?? '',
//               macB64: encryptedMessage['mac'] ?? '',
//             );
            
//             print("Alternative decryption successful: '$alternativeDecrypted'");
//             decryptedMessages[message['messageId']] = alternativeDecrypted;
//             print("=== DECRYPTION DEBUG END (SUCCESS WITH ALT KEY) ===");
//             return;
//           }
//         } catch (e) {
//           print("Alternative decryption also failed: $e");
//         }
//       }
//       print("=== KEY COMPARISON DEBUG END ===");
      
//       SecretKey sharedSecretKey = await generateSharedSecretKey(
//         myPrivateKeySeed: privateKey,
//         receiverPublicKeyBytes: senderPublicKey,
//       );

//       // Verify encrypted message has all required fields
//       if (!encryptedMessage.containsKey('ciphertext') || 
//           !encryptedMessage.containsKey('nonce') || 
//           !encryptedMessage.containsKey('mac')) {
//         print("ERROR: Missing required encryption fields");
//         print("Has ciphertext: ${encryptedMessage.containsKey('ciphertext')}");
//         print("Has nonce: ${encryptedMessage.containsKey('nonce')}");  
//         print("Has mac: ${encryptedMessage.containsKey('mac')}");
//         decryptedMessages[message['messageId']] = "[Invalid message format]";
//         return;
//       }

//       print("Attempting decryption with:");
//       print("Ciphertext length: ${(encryptedMessage['ciphertext'] ?? '').toString().length}");
//       print("Nonce length: ${(encryptedMessage['nonce'] ?? '').toString().length}");
//       print("MAC length: ${(encryptedMessage['mac'] ?? '').toString().length}");

//       String decryptedText = await decryptMessage(
//         aesKey: sharedSecretKey,
//         ciphertextB64: encryptedMessage['ciphertext'] ?? '',
//         nonceB64: encryptedMessage['nonce'] ?? '',
//         macB64: encryptedMessage['mac'] ?? '',
//       );

//       decryptedMessages[message['messageId']] = decryptedText;
//       print("SUCCESS: Decrypted message: '$decryptedText'");
//       print("=== DECRYPTION DEBUG END ===");
//     } catch (e) {
//       print("EXCEPTION: Decryption error for message ${message['messageId']}: $e");
//       print("Exception type: ${e.runtimeType}");
//       print("Stack trace: ${StackTrace.current}");
//       decryptedMessages[message['messageId']] = "[Failed to decrypt message: ${e.toString()}]";
//       print("=== DECRYPTION DEBUG END (WITH ERROR) ===");
//     }
//   }

//   String getDecryptedMessage(String messageId) {
//     return decryptedMessages[messageId] ?? "[Decrypting...]";
//   }

//   void closeChat() async {
//     messages.clear();

//     await _streamSubscription?.cancel();
//     _streamSubscription = null;
//   }

//   void sendMessage() async {
//     if (messageController.text.trim().isEmpty) return;

//     SharedPreferences _prefs = await SharedPreferences.getInstance();
//     String myPrivateKey = await _prefs.getString("private-key") ?? "";

//     print("Attempting to send message...");
//     print("My private key exists: ${myPrivateKey.isNotEmpty}");
//     print("Friend public key: $friendPublicKey");
//     print("Friend public key length: ${friendPublicKey.length}");

//     if (myPrivateKey.isEmpty) {
//       print("ERROR: Missing private key - generating new keys...");
//       await storePrivateKey();
//       myPrivateKey = await _prefs.getString("private-key") ?? "";
      
//       // Update user's public key in Firestore
//       String newPublicKey = await _prefs.getString("public-key") ?? "";
//       if (newPublicKey.isNotEmpty) {
//         await FirebaseProvider.updateMainCollectionDocumentField(
//           'users',
//           currentUserId,
//           'publicKey',
//           newPublicKey,
//         );
//       }
//     }

//     if (friendPublicKey == "NULL" || friendPublicKey.isEmpty) {
//       print("ERROR: Missing friend's public key - cannot encrypt message");
//       Get.snackbar(
//         "Encryption Error", 
//         "Unable to send encrypted message. Friend's encryption key not found.",
//         duration: Duration(seconds: 3),
//       );
//       return;
//     }

//     // Decode and validate key lengths
//     Uint8List privateKey;
//     Uint8List receiverPublicKey;
    
//     try {
//       privateKey = base64Decode(myPrivateKey);
//       receiverPublicKey = base64Decode(friendPublicKey);
      
//       // Validate key lengths
//       if (privateKey.length != 32) {
//         print("Invalid private key length: ${privateKey.length} bytes, expected 32");
//         return;
//       }
      
//       if (receiverPublicKey.length != 32) {
//         print("Invalid public key length: ${receiverPublicKey.length} bytes, expected 32");
//         return;
//       }
//     } catch (e) {
//       print("Error decoding keys: $e");
//       return;
//     }

//     print("Friend Public Key : " + friendPublicKey);

//     // For encryption: Use MY private key + FRIEND's public key
//     print("=== ENCRYPTION DEBUG START ===");
//     print("Encryption: Using my private key + friend's public key");
//     print("My ID: $currentUserId, Friend ID: $friendId");
//     print("My private key (first 20 chars): ${base64Encode(privateKey).substring(0, 20)}...");
//     print("Friend's public key (first 20 chars): ${friendPublicKey.substring(0, 20)}...");
    
//     SecretKey sharedSecretKey = await generateSharedSecretKey(
//       myPrivateKeySeed: privateKey,
//       receiverPublicKeyBytes: receiverPublicKey,
//     );

//     Map<String, String> secureMessageMap = await encryptMessage(
//       aesKey: sharedSecretKey,
//       plainText: messageController.text,
//     );

//     print("Generated encrypted message: $secureMessageMap");
//     print("=== ENCRYPTION DEBUG END ===");

//     String messageId = Uuid().v1();
//     String originalText = messageController.text;

//     // Message
//     Message message = Message(
//       isRead: false,
//       messageId: messageId,
//       securedMessage: secureMessageMap,
//       senderId: currentUserId,
//       time: DateTime.now(),
//     );
//     messageController.clear();

//     // Store the decrypted text for immediate display
//     decryptedMessages[messageId] = originalText;

//     Map<String, dynamic> messageMap = message.toMap();
//     messageMap['time'] = FieldValue.serverTimestamp();
//     final Map<String, dynamic> uploadMap = {...messageMap};

//     // backend - logic
//     messages.insert(0, messageMap);

//     // this will upload the message
//     await FirebaseProvider.uploadDataToSubCollection(
//       uploadMap,
//       'chats',
//       'messages',
//       chatId,
//       message.messageId,
//     );

//     // send notification to other user about new message

//     String? tokenn =
//         await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//           "users",
//           "fcmToken",
//           friendId,
//         );

//     print("Other Friend Token : " + tokenn.toString());

//     if (tokenn != null)
//       await sendPushMessage(
//         tokenn,
//         "messageController.text", // later i need to update this....
//         "New Message Received From " + senderName.toString(),
//         friendId,
//       );

//     // // we need to update the id of last message in chats collection

//     await FirebaseProvider.updateMainCollectionDocumentField(
//       'chats',
//       chatId,
//       'lastMessageId',
//       message.messageId,
//     );
//     await FirebaseProvider.updateMainCollectionDocumentMapAllFieldExceptOne(
//       "chats",
//       chatId,
//       "unRead",
//       currentUserId,
//       count.value.toString(),
//     );
//   }

//   void countUnReadMessages() {
//     count.value = 0;
//     for (var message in messages) {
//       Map<String, dynamic> msg = message;
//       if (msg['isRead'] == false && msg['senderId'] == currentUserId) {
//         count.value++;
//       }
//     }
//   }

//   Future<void> ensureUserHasPublicKeyInFirestore() async {
//     try {
//       String? storedPublicKey = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//         "users",
//         "publicKey",
//         currentUserId,
//       );
      
//       if (storedPublicKey == null || storedPublicKey.isEmpty || storedPublicKey == "NULL") {
//         print("User doesn't have public key in Firestore, updating...");
//         SharedPreferences _prefs = await SharedPreferences.getInstance();
//         String localPublicKey = await _prefs.getString("public-key") ?? "";
        
//         if (localPublicKey.isNotEmpty) {
//           await FirebaseProvider.updateMainCollectionDocumentField(
//             'users',
//             currentUserId,
//             'publicKey',
//             localPublicKey,
//           );
//           print("Updated user's public key in Firestore");
//         }
//       }
//     } catch (e) {
//       print("Error ensuring user has public key: $e");
//     }
//   }

//   /// Test function to verify ECDH key exchange works correctly
//   Future<void> testECDHKeyExchange() async {
//     try {
//       print("=== TESTING ECDH KEY EXCHANGE ===");
      
//       // Get both users' keys
//       SharedPreferences _prefs = await SharedPreferences.getInstance();
//       String myPrivateKeyB64 = await _prefs.getString("private-key") ?? "";
//       String myPublicKeyB64 = await _prefs.getString("public-key") ?? "";
      
//       String? friendPublicKeyB64 = await FirebaseProvider.getFieldOfMainCollectionDocumentField(
//         "users",
//         "publicKey",
//         friendId,
//       );
      
//       if (myPrivateKeyB64.isEmpty || friendPublicKeyB64 == null || friendPublicKeyB64.isEmpty) {
//         print("ERROR: Missing keys for ECDH test");
//         return;
//       }
      
//       Uint8List myPrivateKey = base64Decode(myPrivateKeyB64);
//       Uint8List friendPublicKey = base64Decode(friendPublicKeyB64);
      
//       print("My private key length: ${myPrivateKey.length}");
//       print("Friend's public key length: ${friendPublicKey.length}");
//       print("My public key: $myPublicKeyB64");
//       print("Friend's public key: $friendPublicKeyB64");
      
//       // Generate shared secret from my perspective (for encryption)
//       SecretKey encryptionSecret = await generateSharedSecretKey(
//         myPrivateKeySeed: myPrivateKey,
//         receiverPublicKeyBytes: friendPublicKey,
//       );
      
//       // Generate shared secret from friend's perspective (for decryption simulation)  
//       // This would be: friendPrivateKey + myPublicKey, but we don't have friend's private key
//       // So let's just verify our current approach should work
      
//       String testMessage = "Hello World Test";
      
//       // Encrypt with my keys
//       Map<String, String> encrypted = await encryptMessage(
//         aesKey: encryptionSecret,
//         plainText: testMessage,
//       );
      
//       print("Test encryption successful: $encrypted");
      
//       // Try to decrypt with same secret (this should work)
//       String decrypted = await decryptMessage(
//         aesKey: encryptionSecret,
//         ciphertextB64: encrypted['ciphertext']!,
//         nonceB64: encrypted['nonce']!,
//         macB64: encrypted['mac']!,
//       );
      
//       print("Test decryption result: '$decrypted'");
//       print("Test ${testMessage == decrypted ? 'PASSED' : 'FAILED'}");
//       print("=== ECDH TEST COMPLETE ===");
      
//     } catch (e) {
//       print("ERROR in ECDH test: $e");
//     }
//   }

//   @override
//   void onClose() {
//     messageController.dispose();
//     super.onClose();
//   }

//   @override
//   void onInit() async {
//     var args = Get.arguments;
//     friendName = args['name'];
//     chatId = args['chatId'];
//     friendId = args['friendId'];

//     currentUserId = await FirebaseAuth.instance.currentUser!.uid;
    
//     // Ensure encryption keys exist before opening chat
//     await ensureKeysExist();
    
//     // Ensure user's public key is stored in Firestore
//     await ensureUserHasPublicKeyInFirestore();
    
//     await openChat();
    
//     // Test ECDH key exchange
//     await testECDHKeyExchange();
//     super.onInit();
//   }
// }
