import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';

class AppUtils {
  static List<T> castDynamicList<T>(List<dynamic>? dataList) {
    if (dataList == null) {
      return [];
    }
    return dataList.map((e) => e as T).toList();
  }

  static bool isNullOrEmptyList(List? list) {
    return list == null || list.isEmpty;
  }

  static bool isNullOrEmptyString(String? str) {
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
    BuildContext context,
    String title,
    Widget? content, {
    String continueButtonText = 'Yes',
    String cancelButtonText = 'No',
    MainAxisAlignment actionsAlignment = MainAxisAlignment.spaceAround,
  }) async {
    // set up the buttons
    final Widget continueButton = TextButton(
      child: Text(continueButtonText),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    final Widget cancelButton = TextButton(
      child: Text(cancelButtonText),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );

    final AlertDialog alert = AlertDialog(
      title: Center(child: Text(title)),
      content: content,
      actions: [continueButton, cancelButton],
      actionsAlignment: actionsAlignment,
    );

    final bool confirmation = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            }) ??
        false;

    return confirmation;
  }

  static void showCopied() {
    showToast("Copied to clipboard");
  }

  static void showToast(String text,
      {ToastGravity gravity = ToastGravity.BOTTOM,
      Toast length = Toast.LENGTH_SHORT}) {
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
