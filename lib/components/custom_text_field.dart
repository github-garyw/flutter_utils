import 'package:flutter/material.dart';

import '../app_utils.dart';

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
  final TextEditingController? controller;
  final FieldType fieldType;
  final Function(String?) extraValidation;

  final TextStyle labelTextStyle;

  const CustomTextField(
      {super.key,
      required this.label,
      required this.controller,
      this.desc = '',
      this.isRequired = true,
      this.showRedStar = true,
      this.fieldType = FieldType.Text,
      this.extraValidation = nullFunction,
      this.labelTextStyle = defaultTextStyle16});

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

    if (isRequired && showRedStar) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        TextFormField(
          controller: controller,
          obscureText: fieldType == FieldType.Password,
          decoration: const InputDecoration(
            border: OutlineInputBorder(), // Add border outline here
          ),
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
                isRequired &&
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
