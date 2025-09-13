import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:internee_app3/app/Config/theme_controller.dart';

class ThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ThemeController());
  }
}
