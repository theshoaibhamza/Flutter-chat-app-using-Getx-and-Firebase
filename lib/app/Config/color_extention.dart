// lib/app/Consts/color_extensions.dart
import 'package:flutter/material.dart';

extension AppColorScheme on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  // Add more as needed
}
