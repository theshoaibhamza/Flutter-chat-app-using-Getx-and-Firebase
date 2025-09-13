import 'package:get/get.dart';

import '../controllers/mychats_controller.dart';

class MychatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MychatsController>(
      () => MychatsController(),
    );
  }
}
