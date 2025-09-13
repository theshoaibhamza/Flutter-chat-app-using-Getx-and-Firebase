import 'package:get/get.dart';

import '../controllers/homepages_controller.dart';

class HomepagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomepagesController>(
      () => HomepagesController(),
    );
  }
}
