import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';

class AppUtils {

  static List<T> castDynamicList<T>(List<dynamic> dataList) {
    return dataList.map((e) => e as T).toList();
  }

  static bool isNullOrEmptyString(String str) {
    return str == null || str.trim().isEmpty;
  }

  static String removeNonDigits(String input) {
    return input.replaceAll(
        RegExp(r'\D'), ''); // \D matches any non-digit character
  }

  static bool validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }
    return RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(email);
  }

  static void showPopUp(BuildContext context, String title, String content) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        });
  }

  static Future<bool> showOkPopup(
      BuildContext context, String title, String message) async {
    // set up the buttons
    final Widget continueButton = TextButton(
      child: const Text("Ok"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    final AlertDialog alert = AlertDialog(
        title: Text(title), content: Text(message), actions: [continueButton]);

    final bool confirmation = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });

    return confirmation;
  }

  static Future<bool> showYesNoPopup(
      BuildContext context, String title, String message) async {

    // set up the buttons
    final Widget continueButton = TextButton(
      child: const Text("Yes"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    final Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );

    final AlertDialog alert = AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [continueButton, cancelButton]);

    final bool confirmation = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });

    return confirmation;
  }

  static void showCopied() {
    showToast("Copied to clipboard");
  }

  static void showToast(String text,
      {ToastGravity gravity = ToastGravity.BOTTOM, Toast length = Toast.LENGTH_SHORT}) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: length,
        gravity: gravity,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
