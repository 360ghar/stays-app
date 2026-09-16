import 'package:flutter/material.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({required String titleText, super.key})
    : super(title: Text(titleText));
}
