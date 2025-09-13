import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';

import '../controllers/request_controller.dart';

class RequestView extends GetView<RequestController> {
  const RequestView({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.users.isEmpty)
                return Center(child: Text("No Requests Available"));

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
                          ElevatedButton(
                            onPressed: () async {
                              // Decline Request Logic
                              print("Request Delined");
                              await controller.declineRequest(
                                controller.requests[index]['requestId'],
                                controller.requests[index]['senderId'],
                              );
                            },
                            child: MyText(
                              size: 11,
                              text: "Decline",
                              color: Colors.red.shade500,
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              print("Request Accepted");
                              controller.acceptRequest(
                                controller.requests[index]['senderId'],
                                controller.requests[index]['requestId'],
                              );
                            },
                            child: MyText(
                              text: "Accept",
                              color: Colors.teal,
                              size: 11,
                            ),
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
