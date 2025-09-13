import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/homepages_controller.dart';

class HomepagesView extends GetView<HomepagesController> {
  const HomepagesView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Obx(
          () => ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(20),
            child: BottomNavigationBar(
              currentIndex: controller.currentIndex.value, // Required
              onTap: (value) {
                controller.changePage(value); // ✅ FIXED
              },
              selectedItemColor: Colors.teal, // ✅ Selected icon & label color
              unselectedItemColor:
                  Colors.grey, // ✅ Unselected icon & label color

              showUnselectedLabels:
                  true, // Optional: show label even when not selected
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "Find",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble),
                  label: "Chats",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_people),
                  label: "Requests",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Friends",
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(title: const Text('HomepagesView'), centerTitle: true),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        children: controller.pages,
      ),
    );
  }
}
