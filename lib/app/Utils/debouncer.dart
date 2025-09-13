import 'dart:async';

import 'package:flutter/widgets.dart';

class Debouncer {
  final int miliSeconds;
  Timer? timer;

  Debouncer({required this.miliSeconds, this.timer});

  void run(VoidCallback action) {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: miliSeconds), action);
  }
}
