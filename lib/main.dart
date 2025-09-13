import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internee_app3/Presentation/modules/splash/controllers/splash_controller.dart';
import 'package:internee_app3/app/Config/firebase_messaging.dart';
import 'package:internee_app3/app/Config/theme_binding.dart';
import 'package:internee_app3/app/Config/theme_controller.dart';
import 'package:internee_app3/app/Config/themes.dart';
import 'package:internee_app3/firebase_options.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ThemeBinding().dependencies();
  var themeController = Get.find<ThemeController>();
  Get.put(() => SplashController());
  
  await GetStorage.init();
  configureMessagingPermissions();
  runApp(
    Obx(
      () => GetMaterialApp(
        title: "Application",
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeController.themeMode.value,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    ),
  );
}
