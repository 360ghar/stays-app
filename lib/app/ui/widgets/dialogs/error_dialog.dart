import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showErrorDialog(BuildContext context, {required String message}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('common.error'.tr),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.ok'.tr),
        ),
      ],
    ),
  );
}
