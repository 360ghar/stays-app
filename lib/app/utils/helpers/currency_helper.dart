import 'package:intl/intl.dart';

class CurrencyHelper {
  static const String _defaultSymbol = '\u20B9';

  static String format(
    num value, {
    String locale = 'en_IN',
    String symbol = _defaultSymbol,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  static String formatCompact(num value, {String symbol = _defaultSymbol}) {
    if (value >= 10000000) {
      final formatted = (value / 10000000).toStringAsFixed(1);
      return '$symbol${formatted}Cr';
    }
    if (value >= 100000) {
      final formatted = (value / 100000).toStringAsFixed(1);
      return '$symbol${formatted}L';
    }
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '$symbol${formatted}K';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }

  static String formatArea(num value, {String unit = 'sq ft'}) {
    if (value >= 100000) {
      final formatted = (value / 100000).toStringAsFixed(1);
      return '${formatted}L $unit';
    }
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '${formatted}K $unit';
    }
    return '${value.toStringAsFixed(0)} $unit';
  }
}
