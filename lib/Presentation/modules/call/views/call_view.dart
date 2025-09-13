import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:internee_app3/Presentation/modules/call/controllers/call_controller.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallView extends GetView<CallController> {
  const CallView({Key? key});

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID:
          1096664576, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign:
          "ea8fe120bdf55589dedf96911b5e1cee804e7f18f39051831863ac3cff7fd4be", // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: 'user_id',
      userName: 'user_name',
      callID: "controller.callID.value",
      // You can also use groupVideo/groupVoice/oneOnOneVoice to make more types of calls.
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
