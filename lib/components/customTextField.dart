import 'package:flutter/material.dart';

import '../appUtils.dart';

typedef ValidateFunction = String? Function(String?);

const TextStyle defaultTextStyle16 =
    TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold);

enum FieldType {
  Text,
  Integer,
  Numeric,
  Email,
  Password,
}

String? nullFunction(String? value) {
  return null;
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String desc;
  final bool isRequired;
  final bool showRedStar;
  final bool readonly;
  final TextEditingController? controller;
  final FieldType fieldType;
  final Function(String?) extraValidation;
  final TextStyle labelTextStyle;
  final TextStyle inputTextStyle;
  final int maxLines;
  final FocusNode? focusNode;
  late String? readonlyValue;

  CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.desc = '',
    this.isRequired = true,
    this.showRedStar = true,
    this.maxLines = 1,
    this.readonly = false,
    this.fieldType = FieldType.Text,
    this.extraValidation = nullFunction,
    this.labelTextStyle = defaultTextStyle16,
    this.inputTextStyle = defaultTextStyle16,
    this.focusNode,
  });

  Widget _buildLabel() {
    List<TextSpan> textSpans = [];
    textSpans.add(TextSpan(
      text: label,
      style: labelTextStyle,
    ));

    textSpans.add(TextSpan(
      text: desc,
      style: labelTextStyle,
    ));

    if (isRequired && showRedStar && !readonly) {
      textSpans.add(const TextSpan(
        text: ' *',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
    );
  }

  TextInputType? _getTextInputText() {
    if (fieldType == FieldType.Integer || fieldType == FieldType.Numeric) {
      return TextInputType.number;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (readonly) {
      readonlyValue = controller?.text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        TextFormField(
          keyboardType: _getTextInputText(),
          controller: controller,
          obscureText: fieldType == FieldType.Password,
          maxLines: maxLines,
          readOnly: readonly,
          enabled: !readonly,
          focusNode: focusNode,
          decoration: const InputDecoration(
            border: OutlineInputBorder(), // Add border outline here
          ),
          style: inputTextStyle,
          onChanged: (value) {
            if (readonly) {
              controller?.text = readonlyValue ?? '';
            }
          },
          validator: (value) {
            String trimmedValue = value!.trim();
            if (isRequired && AppUtils.isNullOrEmptyString(trimmedValue)) {
              return '請輸入 $label';
            }
            if (fieldType == FieldType.Integer &&
                int.tryParse(trimmedValue) == null) {
              return '請輸入整數';
            }
            if (fieldType == FieldType.Numeric &&
                double.tryParse(trimmedValue) == null) {
              return '請輸入數字';
            }
            if (fieldType == FieldType.Email &&
                trimmedValue.isNotEmpty &&
                !AppUtils.validateEmail(trimmedValue)) {
              return '電郵格式無效';
            }

            return extraValidation(trimmedValue); // all good
          },
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
