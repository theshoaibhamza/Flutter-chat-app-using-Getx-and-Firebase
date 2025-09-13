import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Presentation/modules/homepages/controllers/homepages_controller.dart';
import 'package:internee_app3/Presentation/modules/mychats/controllers/mychats_controller.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';

class FriendsController extends GetxController {
  RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;

  RxBool isLoading = false.obs;

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
