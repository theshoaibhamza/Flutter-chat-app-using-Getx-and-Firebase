import 'package:flutter/material.dart';
import 'package:internee_app3/app/Widgets/my_text.dart';

abstract class CustomButton {
  Widget build(BuildContext context);
}

class SendRequestButton extends CustomButton {
  final VoidCallback onPressed;

  SendRequestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: MyText(text: "Send Request", color: Colors.teal),
    );
  }
}

class CancelRequestButton extends CustomButton {
  final VoidCallback onPressed;

  CancelRequestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: MyText(text: "Cancel Request", color: Colors.teal),
    );
  }
}

class ViewRequestButton extends CustomButton {
  final VoidCallback onPressed;

  ViewRequestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: MyText(text: "View Request", color: Colors.teal),
    );
  }
}

class RemoveFriendButton extends CustomButton {
  final VoidCallback onPressed;

  RemoveFriendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: MyText(text: "Remove Friend", color: Colors.teal),
    );
  }
}

class ButtonFactory {
  static CustomButton createButton(String buttonType, VoidCallback onPressed) {
    switch (buttonType.toLowerCase()) {
      case 'send request':
        return SendRequestButton(onPressed: onPressed);
      case 'cancel request':
        return CancelRequestButton(onPressed: onPressed);
      case 'view request':
        return ViewRequestButton(onPressed: onPressed);
      case 'remove friend':
        return RemoveFriendButton(onPressed: onPressed);
      default:
        return SendRequestButton(onPressed: onPressed);
    }
  }
}
