import 'package:flutter/widgets.dart';

extension ContextExtensions on BuildContext {
  Size get size => MediaQuery.of(this).size;
}
