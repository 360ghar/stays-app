extension DateTimeExtensions on DateTime {
  bool get isPast => isBefore(DateTime.now());
}
