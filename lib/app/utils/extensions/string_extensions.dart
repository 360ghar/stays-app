extension StringExtensions on String {
  String capitalizeFirst() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

