import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate(DateTime date, {String pattern = 'MMM d, y'}) {
    return DateFormat(pattern).format(date);
  }
}
