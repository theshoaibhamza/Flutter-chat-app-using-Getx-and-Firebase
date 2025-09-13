import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:internee_app3/app/Services/firebase_provider.dart';
import 'package:internee_app3/app/Widgets/my_container.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        

        


        Padding(
          padding: const EdgeInsets.all(20.0),
          child: MyContainer(
            borderRadius: 20,
            height: 100,
            color: Colors.grey.shade300,
            width: double.maxFinite,
            child: Row(
              children: [
                Icon(Icons.person, size: 70),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: "Welcome,",
                      size: 25,
                      fontWeight: FontWeight.bold,
                    ),

                    MyText(text: controller.userModel.name, size: 15),
                  ],
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        print("logging out");
                        await FirebaseProvider.logout();
                      },
                      child: MyText(text: "Logout", color: Colors.red),
                    ),
                    //child: Text('ChatView is working', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
