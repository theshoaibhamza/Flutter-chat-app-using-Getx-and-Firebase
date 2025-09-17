import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/user_model.dart';
import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:internee_app3/app/Services/encryption_service.dart';
import 'package:internee_app3/app/Utils/throttler.dart';

class SignupController extends GetxController {
  RxBool isPasswordObsecure = true.obs;
  RxBool isConfirmPasswordObsecure = true.obs;
  RxBool isLoading = false.obs;

  Throttler throttler = Throttler(miliseconds: 2000);

  var emailController = TextEditingController();
  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  void validateForm() async {
    if (globalKey.currentState!.validate()) {}
  }

  void moveToLogin() async {
    try {
      isLoading.value = true;

      // same or not
      if (passwordController.text == confirmPasswordController.text) {
        // apply backend condition here...

        UserCredential userCredential = await FirebaseProvider.registerUser(
          emailController.text,
          passwordController.text,
        );

        // Step 1: Generate encryption keys for the new user
        final encryptionService = EncryptionService();
        final publicKey = await encryptionService.generateAndStoreKeys();

        UserModel userModel = UserModel.instance;

        userModel.id = userCredential.user!.uid;
        userModel.email = userCredential.user!.email!;
        userModel.publicKey = publicKey; // Store public key in Firestore
        userModel.name = nameController.text;
        userModel.lastLogin = DateTime.now();

        Map<String, dynamic> data = userModel.toMap();

        FirebaseProvider.uploadData(data, 'users', userModel.id);

        Get.offAllNamed('/login');

        Get.snackbar("Signup Success", "Now You Can Login To Your Account.");
      } else {
        Get.snackbar(
          "Failed to Signup",
          "Password and confrim password doesn't match.",
        );
      }

      isLoading.value = false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar(
          "Signup Failed",
          "Account Already Exists With This Email. Please Login Or Try Another",
        );
      } else if (e.code == 'invalid-email') {
        Get.snackbar("Signup Failed", "Invalid Email ");
      } else
        Get.snackbar("Signup Failed", e.toString());
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
