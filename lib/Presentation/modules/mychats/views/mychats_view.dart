import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Data/Models/chat.dart';
import 'package:internee_app3/app/Widgets/my_container.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';
import '../controllers/mychats_controller.dart';

class MychatsView extends GetView<MychatsController> {
  const MychatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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

        if (controller.chats.isEmpty) {
          return Center(
            child: MyText(
              text: "You Have No Chat Yet.",
              fontWeight: FontWeight.bold,
            ),
          );
        }

        // Take local snapshots to avoid mid-build reactive changes
        final List<Chat> chats = List<Chat>.from(controller.chats);
        final List<Map<String, dynamic>> users =
            List<Map<String, dynamic>>.from(controller.users);
        final int itemCount = chats.length < users.length
            ? chats.length
            : users.length;

        return ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final Chat chat = chats[index]; // aligned with itemCount
            final Map<String, dynamic> userMap = index < users.length
                ? users[index]
                : <String, dynamic>{};
            final String userId = (userMap['id']?.toString() ?? '');
            final String userName = (userMap['name']?.toString() ?? '');
            final String userEmail = (userMap['email']?.toString() ?? '');

            // Handle display for group vs individual chats
            final String displayName = chat.isGroup 
                ? (chat.groupName ?? 'Group Chat') 
                : userName;
            final String displaySubtitle = chat.isGroup 
                ? '${chat.users.length} members' 
                : userEmail;

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: chat.isGroup 
                    ? CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.group, color: Colors.white),
                      )
                    : const CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12',
                        ),
                      ),
                title: MyText(text: displayName),
                subtitle: Text(
                  displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chat.time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(width: 10),
                    chat.unRead[controller.currentUserId].toString() == "0"
                        ? Container()
                        : MyContainer(
                            borderRadius: 20,
                            color: Colors.teal,
                            height: 15,
                            width: 15,
                            child: Center(
                              child: MyText(
                                text:
                                    chat.unRead[controller.currentUserId] ??
                                    "null".toString(),
                                size: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ],
                ),
                onTap: () {
                  Map<String, dynamic> args = {
                    "name": displayName,
                    "chatId": chat.chatId,
                    "friendId": chat.isGroup ? null : userId,
                    "isGroup": chat.isGroup,
                  };

                  // Navigate to chat screen
                  Get.toNamed('/chat', arguments: args);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
