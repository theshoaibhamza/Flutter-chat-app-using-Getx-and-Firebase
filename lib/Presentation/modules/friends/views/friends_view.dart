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
          // Header row with New Group / Cancel and selected count
          Obx(() {
            final bool isSelecting = controller.selectionMode.value;
            final int selectedCount = controller.selectedUserIds.length;
            return Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    print('New Group button pressed. Current selection mode: ${controller.selectionMode.value}');
                    if (isSelecting && selectedCount > 0) {
                      // Clear selections when canceling
                      controller.clearSelections();
                    }
                    controller.toggleSelectionMode();
                    print('New selection mode: ${controller.selectionMode.value}');
                  },
                  icon: Icon(isSelecting ? Icons.close : Icons.group_add),
                  label: Text(isSelecting ? 'Cancel' : 'New Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                if (isSelecting)
                  Text(
                    selectedCount > 0
                        ? '$selectedCount selected'
                        : 'Select friends',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
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
                  // Safety check for index bounds
                  if (index >= controller.users.length || index >= controller.friends.length) {
                    return Container();
                  }
                  
                  final Map<String, dynamic> user = controller.users[index];
                  final Map<String, dynamic> friend = controller.friends[index];
                  final String userId = friend['friendId']?.toString() ?? '';
                  final String userName = user['name']?.toString() ?? 'Unknown';
                  final String userEmail = user['email']?.toString() ?? '';
                  
                  return Obx(() {
                    final bool selectionMode = controller.selectionMode.value;
                    final bool isChecked = controller.isUserSelected(userId);
                    
                    return Card(
                      elevation: selectionMode && isChecked ? 4.0 : 1.0,
                      color: selectionMode && isChecked 
                          ? Colors.teal.shade50 
                          : null,
                      child: InkWell(
                        onTap: selectionMode 
                            ? () {
                                print('Tapping user: $userId');
                                controller.toggleUserSelection(userId);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // User avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isChecked 
                                    ? Colors.teal 
                                    : Colors.grey.shade300,
                                child: isChecked && selectionMode
                                    ? Icon(Icons.check, color: Colors.white)
                                    : Text(
                                        userName.isNotEmpty 
                                            ? userName[0].toUpperCase() 
                                            : 'U',
                                        style: TextStyle(
                                          color: isChecked 
                                              ? Colors.white 
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // User info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText(
                                      text: userName,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    const SizedBox(height: 4),
                                    MyText(
                                      text: userEmail,
                                      color: Colors.grey,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              if (!selectionMode) ...[
                                IconButton(
                                  onPressed: () async {
                                    // Remove friend Logic
                                    await controller.removeFriend(
                                      friend['friendShipId'], // friendshipId
                                      friend['friendId'], // friendId
                                    );
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Remove Friend',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    // move to all my chats
                                    controller.moveToMyChats(
                                      friend['friendId'],
                                    );
                                  },
                                  icon: Icon(Icons.chat, color: Colors.teal),
                                  tooltip: 'Start Chat',
                                ),
                              ] else ...[
                                // Selection checkbox for group creation
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    print('Checkbox changed for user: $userId, value: $value');
                                    controller.toggleUserSelection(userId);
                                  },
                                  activeColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
          // Bottom Create Group button
          Obx(() {
            final bool isSelecting = controller.selectionMode.value;
            final bool canCreate = controller.selectedUserIds.isNotEmpty;
            if (!isSelecting) return SizedBox.shrink();
            return SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canCreate
                      ? () async {
                          // Show dialog to get group name
                          final TextEditingController groupNameController = 
                              TextEditingController();
                          
                          final String? groupName = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Create Group'),
                                content: TextField(
                                  controller: groupNameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter group name',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLength: 50,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final name = groupNameController.text.trim();
                                      if (name.isNotEmpty) {
                                        Navigator.of(context).pop(name);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Create'),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (groupName != null && groupName.isNotEmpty) {
                            await controller.createSelectedGroup(groupName);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Create Group'),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
