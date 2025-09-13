import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:internee_app3/Presentation/modules/signup/controllers/signup_controller.dart';
import 'package:internee_app3/app/Widgets/my_container.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';
import 'package:internee_app3/app/Widgets/my_text_form_field.dart';

// ignore: must_be_immutable
class SignupView extends GetView<SignupController> {
  SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 120),
          Center(child: Icon(Icons.person, size: 190)),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: controller.globalKey,
              child: Column(
                children: [
                  MyTextFormField(
                    onChanged: (p0) => controller.validateForm(),
                    textEditingController: controller.nameController,
                    label: MyText(text: "Enter Name"),
                    radius: 5,
                  ),
                  SizedBox(height: 10),

                  MyTextFormField(
                    validator: (value) {
                      if (!value!.contains('@gmail.com')) {
                        return "Email Badly Formated! ";
                      }
                      return null;
                    },
                    onChanged: (p0) => controller.validateForm(),
                    textEditingController: controller.emailController,
                    label: MyText(text: "Enter Email"),
                    radius: 5,
                  ),
                  SizedBox(height: 10),
                  Obx(
                    () => MyTextFormField(
                      validator: (p0) {
                        if (p0!.length < 6) {
                          return "Please Enter At Least 6 Digit Password!";
                        }
                        return null;
                      },
                      textLength: 6,
                      onChanged: (p0) => controller.validateForm(),
                      textEditingController: controller.passwordController,
                      label: MyText(text: "Enter Password"),
                      radius: 5,
                      obsecure: controller.isPasswordObsecure.value,
                      suffix: IconButton(
                        onPressed: () {
                          controller.isPasswordObsecure.toggle();
                        },
                        icon: Icon(
                          controller.isPasswordObsecure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Obx(
                    () => MyTextFormField(
                      validator: (p0) {
                        if (p0!.length < 6) {
                          return "Please Enter At Least 6 Digit Password!";
                        } else if (controller.passwordController.text !=
                            controller.confirmPasswordController.text) {
                          return "Password and Confrim Password doesn't match.";
                        }
                        return null;
                      },
                      textLength: 6,
                      onChanged: (p0) => controller.validateForm(),
                      textEditingController:
                          controller.confirmPasswordController,
                      label: MyText(text: "Confirm Password"),
                      radius: 5,
                      obsecure: controller.isConfirmPasswordObsecure.value,
                      suffix: IconButton(
                        onPressed: () {
                          controller.isConfirmPasswordObsecure.toggle();
                        },
                        icon: Icon(
                          controller.isConfirmPasswordObsecure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MyText(text: "Already have an account? "),
                      MyContainer(
                        height: 30,
                        width: 50,
                        onTap: () {
                          Get.offAllNamed('/login');
                        },
                        child: MyText(
                          text: "Login",
                          size: 15,
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Obx(
                    () => MyContainer(
                      onTap: () {
                        controller.throttler.run(() {
                          controller.validateForm();
                          if (controller.globalKey.currentState!.validate()) {
                            controller.moveToLogin();
                          }
                        });
                      },
                      color: Colors.teal,
                      borderRadius: 5,
                      height: 40,
                      width: 140,
                      child: controller.isLoading.value
                          ? Container(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : MyText(
                              text: "Signup",
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          Container(
            height: 1,
            width: double.maxFinite,
            color: Colors.grey.shade300,
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("Assets/google_logo.png", scale: 8),
                MyText(
                  text: "  Sign up With Google",
                  fontWeight: FontWeight.bold,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
