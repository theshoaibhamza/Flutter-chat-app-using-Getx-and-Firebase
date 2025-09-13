import 'dart:async';

import 'package:flutter/material.dart';

class Throttler {
  final int miliseconds;
  Timer? timer;
  bool isReady = true;

  Throttler({required this.miliseconds});

  void run(VoidCallback action) {
    if (isReady) {
      isReady = false;
      action();
      timer = Timer(Duration(milliseconds: miliseconds), () {
        isReady = true;
      });
    }
  }
}
