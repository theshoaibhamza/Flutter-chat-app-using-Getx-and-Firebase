import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/request.dart';
import 'package:internee_app3/Presentation/modules/friends/controllers/friends_controller.dart';
import 'package:internee_app3/Presentation/modules/homepages/controllers/homepages_controller.dart';
import 'package:internee_app3/Presentation/modules/request/controllers/request_controller.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:internee_app3/app/Utils/debouncer.dart';
import 'package:internee_app3/app/Utils/throttler.dart';
import 'package:uuid/uuid.dart';
// import 'package:internee_app3/app/Services/firebase_provider.dart';

class SearchController extends GetxController {
  var searchController = TextEditingController().obs;
  String requestID = Uuid().v1();
  Debouncer debouncer = Debouncer(miliSeconds: 1000);
  Throttler throttler = Throttler(miliseconds: 4000);
  var homeController = Get.find<HomepagesController>();
  RxString buttonType = "Send Request".obs;

  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  // Friends Controller
  var friendsController = Get.find<FriendsController>();
  // Friends Controller
  var requestsController = Get.find<RequestController>();

  void search() async {
    buttonType.value = "Send Request";
    users.value = await FirebaseProvider.searchData(
      collectionPath: 'users',
      field: 'email',
      searchText: searchController.value.text.toLowerCase(),
    );

    // Flow Of Conditions Should Be

    // Already Friend?
    // Already Requested To Be A Friend
    // Request Already Sent
    // Send Request

    for (var user in users) {
      // this is for not allowing the current user to search himself
      if (user['id'] == await FirebaseAuth.instance.currentUser!.uid) {
        users.remove(user);
        return;
      }

      // Check if this user is in friends list
      bool alreadyFriend = friendsController.users.any(
        (friend) => friend['email'] == user['email'],
      );
      if (alreadyFriend) buttonType.value = "Remove Friend";

      // Check if searched user has already requested to be a friend
      await requestsController.getRequests();
      bool alreadyRequested = requestsController.users.any(
        (requestedFriend) => requestedFriend['email'] == user['email'],
      );
      if (alreadyRequested) buttonType.value = "View Request";

      // Check Already Request Is Sent, If Yes Show Cancel Request Button

      bool requestSend = await FirebaseProvider.checkFieldValueInSubcollection(
        parentCollection: 'users',
        parentDocId: user['id'],
        subcollectionName: 'requests',
        fieldName: 'senderId',
        fieldValue: await FirebaseAuth.instance.currentUser!.uid,
      );

      if (requestSend) {
        print("Request already Send" + requestSend.toString());
        buttonType.value = "Cancel Request";
      }

      // Set a flag inside the user map
      user['buttonType'] = buttonType.value;
    }

    // Force the UI to refresh after modifying the list
    users.refresh();
  }

  Future<void> sendRequest(String receiverId, String friendId) async {
    Request request = Request(
      createdAt: DateTime.now(),
      senderId: FirebaseAuth.instance.currentUser!.uid,
      requestId: requestID + friendId,
    );

    await FirebaseProvider.uploadDataToSubCollection(
      request.toMap(),
      'users',
      'requests',
      receiverId,
      request.requestId,
    );
  }

  // cancel Request
  Future<void> cancelRequest(String receiverId, String requestId) async {
    await FirebaseProvider.deleteSubCollectionDocument(
      'users',
      receiverId,
      'requests',
      requestId,
    );
  }
  // search Operation

  void searchOperation(int index) async {
    print("Search Operation Working");

    // This function will be called when the Button Pressed.
    if (index < 0 || index >= users.length) return;

    final String? currentType = users[index]['buttonType']?.toString();

    // show loading state immediately
    users[index]['buttonType'] = null;
    users.refresh();

    // Remove Friend
    if (currentType == "Remove Friend") {
      await friendsController.removeFriend(
        await FirebaseProvider.getDocumentIdByFieldOfSubCollection(
              collectionname: "users",
              mainCollectionId: await FirebaseAuth.instance.currentUser!.uid,
              subCollectionPath: 'friends',
              field: 'friendId',
              value: users[index]['id'],
            ) ??
            "",
        users[index]['id'], // freind id
      );
      users[index]['buttonType'] = "Send Request";
      users.refresh();
    }
    // Cancel Request
    else if (currentType == "Cancel Request") {
      await cancelRequest(
        users[index]['id'],
        await FirebaseProvider.getDocumentIdByFieldOfSubCollection(
              collectionname: 'users',
              mainCollectionId: users[index]['id'],
              subCollectionPath: 'requests',
              field: 'senderId',
              value: await FirebaseAuth.instance.currentUser!.uid,
            ) ??
            "",
      );
      users[index]['buttonType'] = "Send Request";
      users.refresh();
    }
    // View Request
    else if (currentType == "View Request") {
      //Get.toNamed('/request');
      users[index]['buttonType'] = "View Request";
      homeController.changePage(3);
      users.refresh();
    }
    // send request
    else {
      await sendRequest(
        users[index]['id'],
        await FirebaseAuth.instance.currentUser!.uid,
      );
      users[index]['buttonType'] = "Cancel Request";
      users.refresh();
    }
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    searchController.value.dispose();
    super.onClose();
  }
}
