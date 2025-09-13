import 'package:flutter/material.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({super.key, required String titleText})
    : super(title: Text(titleText));
}
