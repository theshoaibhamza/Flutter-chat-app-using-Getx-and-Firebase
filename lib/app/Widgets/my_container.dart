import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyContainer extends StatelessWidget {
  MyContainer({
    super.key,
    required this.height,
    required this.width,
    required this.child,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  double height;
  double width;
  Color? color;
  Widget child;
  GestureTapCallback? onTap;
  double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        child: Center(child: child),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius ?? 0),
        ),
      ),
    );
  }
}
