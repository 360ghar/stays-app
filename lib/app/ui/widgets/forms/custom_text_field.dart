import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const CustomTextField({super.key, required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, decoration: InputDecoration(hintText: hint));
}

