import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class MyText extends StatelessWidget {
  MyText({
    super.key,
    required this.text,
    this.color,
    this.fontFamily,
    this.fontWeight,
    this.size,
  });

  String text;
  Color? color;
  double? size;
  FontWeight? fontWeight;
  String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.getFont(
        fontFamily ?? 'Lato',
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
