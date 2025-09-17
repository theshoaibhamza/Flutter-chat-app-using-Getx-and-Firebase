import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Presentation/modules/homepages/controllers/homepages_controller.dart';
import 'package:internee_app3/Presentation/modules/mychats/controllers/mychats_controller.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';

class FriendsController extends GetxController {
  RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;

  RxBool isLoading = false.obs;
  // Group selection state
  RxBool selectionMode = false.obs;
  RxList<String> selectedUserIds = <String>[].obs;

  var homePagesController = Get.find<HomepagesController>();
  var myChatsController = Get.find<MychatsController>();

  void getFriends() async {
    isLoading.toggle();

    await Future.delayed(Duration(milliseconds: 100));
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseProvider.fetchSubCollection(
      'users',
      currentUserId,
      'friends',
    ).listen((friendsList) async {
      friends.value = friendsList;

      users.clear();

      for (var friend in friendsList) {
        print("working");
        Map<String, dynamic> user = await FirebaseProvider.getData(
          'users',
          friend['friendId'],
        );
        users.add(user);
      }
    });
    isLoading.toggle();
  }

  // Remove Friend

  Future<void> removeFriend(String friendShipId, String friendId) async {
    await FirebaseProvider.deleteSubCollectionDocument(
      'users',
      await FirebaseAuth.instance.currentUser!.uid,
      'friends',
      friendShipId,
    );

    // also remove from friend's friend

    await FirebaseProvider.deleteSubCollectionDocument(
      'users',
      friendId,
      'friends',
      friendShipId,
    );

    removeUserById(friendId);
  }

  void removeUserById(String userId) {
    users.removeWhere((user) => user['id'] == userId);
  }

  void moveToChat(String friendId) {
    Get.toNamed('/chat', arguments: friendId);
  }

  void moveToMyChats(String friendId) async {
    await myChatsController.createChatIfNotExists(friendId);
    homePagesController.changePage(2);
  }

  // Group selection helpers
  void toggleSelectionMode() {
    selectionMode.toggle();
    if (selectionMode.isFalse) {
      selectedUserIds.clear();
    }
    // Force UI refresh
    update();
  }

  void toggleUserSelection(String userId) {
    if (userId.isEmpty) return;
    
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
    
    // Explicitly trigger reactive update
    selectedUserIds.refresh();
    print('Selected users: ${selectedUserIds.toList()}');
  }

  bool isUserSelected(String userId) {
    if (userId.isEmpty) return false;
    return selectedUserIds.contains(userId);
  }

  void clearSelections() {
    selectedUserIds.clear();
    selectedUserIds.refresh();
  }

  Future<void> createSelectedGroup(String groupName) async {
    if (selectedUserIds.isEmpty) return;
    
    try {
      await myChatsController.createGroupChat(
        List<String>.from(selectedUserIds),
        groupName,
      );
      
      // reset state
      clearSelections();
      selectionMode.value = false;
      
      // navigate to My Chats tab
      homePagesController.changePage(2);
      
      // Show success message
      Get.snackbar(
        'Success',
        'Group "$groupName" created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.teal.shade100,
        colorText: Colors.teal.shade800,
      );
    } catch (e) {
      print('Error creating group: $e');
      Get.snackbar(
        'Error',
        'Failed to create group: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  @override
  void onInit() {
    print("Got friends");
    getFriends();
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
