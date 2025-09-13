import 'package:get/get.dart';

class CallController extends GetxController {
  RxString callID = "".obs;


  @override
  void onInit() {
    var args = Get.arguments;
    callID.value = args['callId'];
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }


}
