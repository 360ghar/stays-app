import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => TextFormField(
    decoration: InputDecoration(labelText: label),
    style: const TextStyle(color: Colors.black),
  );
}
