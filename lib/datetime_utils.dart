import 'package:intl/intl.dart';

class DateTimeUtils {

  static final format_yMdHm = DateFormat('yyyy-MM-dd HH:mm', 'en_US');

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