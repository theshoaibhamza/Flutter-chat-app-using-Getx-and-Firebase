import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';

import '../controllers/friends_controller.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value == true) {
                return Center(
                  child: Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                );
              }

              if (controller.users.length <= 0)
                return Center(child: Text("You Have No Friends"));

              return ListView.builder(
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(text: controller.users[index]['name']),
                              MyText(
                                text: controller.users[index]['email'],
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () async {
                              // Remove friend Logic
                              await controller.removeFriend(
                                controller
                                    .friends[index]['friendShipId'], // friendshipId
                                controller
                                    .friends[index]['friendId'], // friendId
                              );
                            },
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            onPressed: () async {
                              // move to all my chats
                              controller.moveToMyChats(
                                controller.friends[index]['friendId'],
                              );

                              // to move to individual chat
                              // controller.moveToChat(
                              //   controller.friends[index]['friendId'],
                              // );
                            },
                            icon: Icon(Icons.chat, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
