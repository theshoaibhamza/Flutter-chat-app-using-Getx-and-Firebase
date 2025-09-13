import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internee_app3/app/Utils/time_utils.dart';
import '../controllers/chat_controller.dart';


class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    // Open chat when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openChat();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            controller.closeChat();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                "https://i.pravatar.cc/150?img=5", //
              ),
            ),
            SizedBox(width: 10),

            Text(controller.friendName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(
              () => ListView.builder(
                reverse: true, // Newest at bottom
                padding: const EdgeInsets.all(8),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMe = controller.currentUserId == message['senderId'];
                  final formattedTime = TimeUtils.formatToTime(message['time']);

                  print("Sender ID : " + message['senderId']);
                  print("My ID : " + controller.currentUserId);
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.teal : Colors.grey.shade300,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMe
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: isMe
                              ? Radius.zero
                              : const Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'].toString(),
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              isMe
                                  ? Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: message['isRead']
                                          ? Colors.white
                                          : Colors.black,
                                    )
                                  : Container(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Message input
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.teal,
                        controller: controller.messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.teal),
                      onPressed: controller.sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
