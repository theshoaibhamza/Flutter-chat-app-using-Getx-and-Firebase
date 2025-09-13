import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:uuid/uuid.dart';

class RequestController extends GetxController {
  RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;

  Future<void> getRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseProvider.fetchSubCollection(
      'users',
      currentUserId,
      'requests',
    ).listen((requestsList) async {
      requests.value = requestsList;

      users.clear();

      for (var request in requestsList) {
        print("working");
        Map<String, dynamic> user = await FirebaseProvider.getData(
          'users',
          request['senderId'],
        );
        users.add(user);
      }
    });
  }

  Future<void> declineRequest(String requestId, String senderId) async {
    await FirebaseProvider.deleteSubCollectionDocument(
      'users',
      await FirebaseAuth.instance.currentUser!.uid,
      'requests',
      requestId,
    );

    removeUserById(senderId);
  }

  void removeUserById(String userId) {
    users.removeWhere((user) => user['id'] == userId);
  }

  Future<void> acceptRequest(String userId, String requestId) async {
    String friendShipId = Uuid().v1();
    await FirebaseProvider.uploadDataToSubCollection(
      {
        "friendId": userId,
        "becameFriendsOn": DateTime.now(),
        "friendShipId": friendShipId,
      },
      'users',
      'friends',
      await FirebaseAuth.instance.currentUser!.uid,
      friendShipId,
    );

    await FirebaseProvider.uploadDataToSubCollection(
      {
        "friendId": await FirebaseAuth.instance.currentUser!.uid,
        "becameFriendsOn": DateTime.now(),
        "friendShipId": friendShipId,
      },
      'users',
      'friends',
      userId,
      friendShipId,
    );

    removeUserById(userId);

    // will see this later

    await FirebaseProvider.deleteSubCollectionDocument(
      'users',
      await FirebaseAuth.instance.currentUser!.uid,
      'requests',
      requestId,
    );
  }

  @override
  void onInit() async {
    print("Got");
    getRequests();
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
