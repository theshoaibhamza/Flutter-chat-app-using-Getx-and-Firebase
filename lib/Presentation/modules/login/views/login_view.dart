import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:internee_app3/app/Widgets/my_container.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';
import 'package:internee_app3/app/Widgets/my_text_form_field.dart';

import '../controllers/login_controller.dart';

// ignore: must_be_immutable
class LoginView extends GetView<LoginController> {
  LoginView({super.key});

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
                      textLength: 6,
                      onChanged: (p0) => controller.validateForm(),
                      textEditingController: controller.passwordController,
                      label: MyText(text: "Enter Password"),
                      radius: 5,
                      obsecure: controller.isObsecure.value,
                      suffix: IconButton(
                        onPressed: () {
                          controller.isObsecure.toggle();
                        },
                        icon: Icon(
                          controller.isObsecure.value
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
                      MyText(text: "Don't have an account? "),
                      MyContainer(
                        height: 30,
                        width: 50,
                        onTap: () {
                          Get.offAllNamed('/signup');
                        },
                        child: MyText(
                          text: "Signup",
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
                          if (!controller.isLoading.value) {
                            controller.validateForm();
                            if (controller.globalKey.currentState!.validate()) {
                              controller.moveToHome();
                            }
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
                              text: "Login",
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
                  text: "  Sign in With Google",
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
