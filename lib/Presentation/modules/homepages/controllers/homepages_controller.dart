import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:internee_app3/Presentation/modules/mychats/controllers/mychats_controller.dart';
import 'package:internee_app3/Presentation/modules/mychats/views/mychats_view.dart';
import 'package:internee_app3/Presentation/modules/profile/controllers/profile_controller.dart';

import 'package:internee_app3/Presentation/modules/profile/views/profile_view.dart';
import 'package:internee_app3/Presentation/modules/friends/controllers/friends_controller.dart';
import 'package:internee_app3/Presentation/modules/friends/views/friends_view.dart';
import 'package:internee_app3/Presentation/modules/request/controllers/request_controller.dart';
import 'package:internee_app3/Presentation/modules/request/views/request_view.dart';
import 'package:internee_app3/Presentation/modules/search/controllers/search_controller.dart';
import 'package:internee_app3/Presentation/modules/search/views/search_view.dart';

class HomepagesController extends GetxController {
  RxList<Widget> pages = [
    ProfileView(),
    SearchView(),
    MychatsView(),
    RequestView(),
    FriendsView(),
  ].obs;
  late PageController pageController;
  RxInt currentIndex = 0.obs;

  void updateIndex(int index) {
    currentIndex.value = index;
  }

  @override
  void onInit() {
    print("I called!");
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => SearchController());
    Get.lazyPut(() => RequestController());
    Get.lazyPut(() => FriendsController());
    Get.lazyPut(() => MychatsController());

    pageController = PageController(initialPage: currentIndex.value);
    super.onInit();
  }

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  void onPageChanged(int index) {
    var searchController = Get.find<SearchController>();
    searchController.searchController.value.clear();
    searchController.users.clear();

    currentIndex.value = index;
  }

  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
