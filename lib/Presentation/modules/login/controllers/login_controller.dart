import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/user_model.dart';
import 'package:internee_app3/app/Config/firebase_messaging.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:internee_app3/app/Utils/throttler.dart';

class LoginController extends GetxController {
  RxBool isObsecure = true.obs;
  RxBool isLoading = false.obs;

  Throttler throttler = Throttler(miliseconds: 2000);

  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  void validateForm() async {
    if (globalKey.currentState!.validate()) {}
  }

  void moveToHome() async {
    try {
      isLoading.value = true;

      // apply backend condition here...

      UserCredential userCredential = await FirebaseProvider.loginUser(
        emailController.text,
        passwordController.text,
      );

      print("token : " + token.toString());

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .update({"fcmToken": token});

      Map<String, dynamic> map = await FirebaseProvider.getData(
        'users',
        userCredential.user!.uid,
      );

      UserModel.initialize(map);

      Get.offAllNamed('/homepages');
      Get.snackbar(
        "Login Success",
        "Logged in successfully",
        duration: Duration(seconds: 1),
      );

      isLoading.value = false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential')
        Get.snackbar("Login Failed", "Incorrect Email or Password");
      else if (e.code == 'user-not-found') {
        Get.snackbar(
          "Login Failed",
          "User doesn't exist. if you don't have an account, please Signup",
        );
      } else if (e.code == 'invalid-email') {
        Get.snackbar("Login Failed", "Invalid Email (Must Add @gmail.com)");
      } else if (e.code == 'too-many-requests') {
        Get.snackbar(
          "Login Failed",
          "Too many Requests, Please Try Again Later",
        );
      } else {
        Get.snackbar("Login Failed", e.toString());
      }
      isLoading.value = false;
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
    super.onClose();
  }
}
