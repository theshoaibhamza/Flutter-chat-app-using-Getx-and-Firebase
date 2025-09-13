import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyTextFormField extends StatelessWidget {
  MyTextFormField({
    super.key,
    required this.textEditingController,
    this.hintText,
    this.label,
    this.radius,
    this.obsecure = false,
    this.suffix,
    this.onChanged,
    this.textLength = 0,
    this.validator,
  });

  Widget? label;
  TextEditingController textEditingController;
  String? hintText;
  double? radius;
  bool? obsecure;
  IconButton? suffix;
  void Function(String)? onChanged;
  num textLength = 0;
  String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    // var themeContaoller = Get.find<ThemeController>();
    return TextFormField(
      onChanged: onChanged,
      cursorColor: Colors.teal,
      obscureText: obsecure ?? false,
      validator: (value) {
        if (value!.isEmpty || value.length <= 0) {
          return "Please Enter Field";
        }
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
      controller: textEditingController,

      decoration: InputDecoration(
        suffixIcon: suffix,
        label: label,

        labelStyle: Theme.of(context).textTheme.bodyMedium,
        hint: Text(hintText ?? ""),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black, // adapts to theme
          ),
          borderRadius: BorderRadius.circular(radius ?? 0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? 0),
        ),
      ),
    );
  }
}
