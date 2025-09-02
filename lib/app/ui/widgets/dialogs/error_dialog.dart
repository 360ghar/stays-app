import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, {required String message}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

