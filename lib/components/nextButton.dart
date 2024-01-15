import 'package:flutter/material.dart';

class NextButton extends StatefulWidget {
  static Future<bool> _defaultReturn() async {
    return true; // or any other default logic
  }

  final BuildContext context;
  final String routeTo;
  final Future<bool> Function() _actionBeforeRoute;
  String text;

  NextButton(
      {super.key,
      this.text = '下一頁',
      required this.context,
      required this.routeTo,
      Future<bool> Function() actionBeforeRoute = _defaultReturn})
      : _actionBeforeRoute = actionBeforeRoute;

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {
  bool _isButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          disabledForegroundColor: Colors.grey.withOpacity(0.38),
          disabledBackgroundColor: Colors.grey.withOpacity(0.12),
        ),
          onPressed: _isButtonDisabled ?  null : () async {
          setState(() {
            _isButtonDisabled = true;
          });
          if (await widget._actionBeforeRoute()) {
            Navigator.pushReplacementNamed(context, widget.routeTo);
          }
          setState(() {
            _isButtonDisabled = false;
          });
        },
        child: Text(
          widget.text,
          style: TextStyle(color: Theme.of(context).canvasColor),
        ));
  }
}
