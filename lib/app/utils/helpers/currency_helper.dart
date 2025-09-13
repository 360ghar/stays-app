import 'package:intl/intl.dart';

class CurrencyHelper {
  static String format(
    num value, {
    String locale = 'en_IN',
    String symbol = '₹',
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
