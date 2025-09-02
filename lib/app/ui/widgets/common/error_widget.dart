import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  const ErrorDisplay({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

