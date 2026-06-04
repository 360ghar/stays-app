import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  const DatePickerField({super.key, required this.label});
  @override
  Widget build(BuildContext context) => TextFormField(
    decoration: InputDecoration(labelText: label),
    style: const TextStyle(color: Colors.black),
  );
}
