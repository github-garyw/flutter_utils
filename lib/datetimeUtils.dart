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

}