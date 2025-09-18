import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('common.cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('common.confirm'.tr),
        ),
      ],
    ),
  );
}
