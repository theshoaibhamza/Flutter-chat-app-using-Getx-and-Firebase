import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.onInit; // Question to ask
    return Scaffold(
      body: Center(
        child: Container(
          height: 230,
          width: 230,
          child: Lottie.asset("Assets/Lottie/loader.json"),
        ),
      ),
    );
  }
}
