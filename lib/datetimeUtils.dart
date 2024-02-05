import 'dart:math';

import 'package:intl/intl.dart';

class DateTimeUtils {
  static final format_yMdHm = DateFormat('yyyy-MM-dd HH:mm', 'en_US');
  static final format_yMd = DateFormat('yyyy-MM-dd', 'en_US');
  static final format_Hm = DateFormat('HH:mm', 'en_US');

  static String toLocalyHm(DateTime dateTime) {
    return format_Hm.format(dateTime);
  }

  static String toLocalyMd(DateTime dateTime) {
    return format_yMd.format(dateTime);
  }

  static String toLocalyMdHm(DateTime dateTime) {
    return format_yMdHm.format(dateTime);
  }

  // Return mockedDateTime if not null and mocked = true, otherwise DateTime.now()
  static DateTime getCurrentDateTime(String? mockedDateTimeString) {
    if (mockedDateTimeString == null) {
      return DateTime.now();
    }
    return DateTime.parse(mockedDateTimeString);
  }

  static DateTime addMonths(DateTime date, {int monthsToAdd = 1}) {
    var year = date.year + ((date.month + monthsToAdd) ~/ 12);
    var month = (date.month + monthsToAdd) % 12;
    if (month == 0) month = 12;
    var day = date.day;

    // Adjust day if the result is an invalid date, e.g., adding a month to January 31st
    if (day > 28) {
      day = min(day, DateTime(year, month + 1, 0).day);
    }

    return DateTime(year, month, day, date.hour, date.minute, date.second,
        date.millisecond, date.microsecond);
  }

}
