import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/chat.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:intl/intl.dart';

import 'package:uuid/uuid.dart';

class MychatsController extends GetxController {
  // Create Chat
  RxList<Chat> chats = <Chat>[].obs;
  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;

  String currentUserId = "";

  Future<void> createChatIfNotExists(String myFriendId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    // Step 1: Check if chat already exists
    QuerySnapshot existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .get();

    String? existingChatId;

    for (var doc in existingChat.docs) {
      List users = doc['users'];
      if (users.contains(myFriendId)) {
        existingChatId = doc.id;

        break;
      }
    }

    // Step 2: If chat exists, use it
    if (existingChatId != null) {
      print("Chat already exists with id: $existingChatId");
      return;
    }

    // Step 3: If chat doesn't exist, create a new one
    String chatId = const Uuid().v1();
    Chat chat = Chat(
      unRead: {currentUserId: 0, myFriendId: 0},
      chatId: chatId,
      createdBy: currentUserId,
      time: DateFormat.jm().format(DateTime.now()),
      users: [currentUserId, myFriendId],
      lastMessageId: "null-initially",
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set(chat.toMap());

    print("New chat created with id: $chatId");
  }

  // getChats
  Future<void> getChats() async {
    isLoading.toggle();
    await Future.delayed(Duration(milliseconds: 100));
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    print("Getting chats for user: $currentUserId");

    await FirebaseProvider.fetchMainCollectionWhereArrayContains(
      'chats',
      'users',
      currentUserId,
    ).listen(
      (data) async {
        chats.value = data.map((map) => Chat.fromMap(map)).toList();
        print("Parsed ${chats.length} chats");

        // Fetch and place each other user's document at the matching chat index
        for (int i = 0; i < chats.length; i++) {
          final Chat chat = chats[i];
          final String otherUserId = chat.users.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );

          print("Other User ID : " + otherUserId);
          Map<String, dynamic> map = await FirebaseProvider.getData(
            'users',
            otherUserId,
          );
          users.add(map);
          users.refresh();
        }

        print("Users length : " + users.length.toString());
      },
      onError: (error) {
        print("Error fetching chats: $error");
      },
    );
    isLoading.toggle();
  }

  void updateCount(int count) async {}

  void complete() async {
    currentUserId = await FirebaseAuth.instance.currentUser!.uid;
    await getChats();
  }

  @override
  void onInit() {
    complete();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
