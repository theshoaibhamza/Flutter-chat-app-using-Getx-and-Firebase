import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/user_model.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';

class SplashController extends GetxController {
  final count = 0.obs;
  @override
  void onInit() async {
    super.onInit();

    await Future.delayed(Duration(seconds: 2));
    print("worked");

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onMessageOpenedApp: ${message.data}");

      print("Time To Navigate");
    });

    bool check = await checkLogin();

    if (check) {
      Get.offAllNamed('/homepages');
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<bool> checkLogin() async {
    User? user = await FirebaseAuth.instance.currentUser;

    if (user != null) {
      Map<String, dynamic> map = await FirebaseProvider.getData(
        'users',
        user.uid,
      );

      UserModel.initialize(map);

      return true;
    } else {
      return false;
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
