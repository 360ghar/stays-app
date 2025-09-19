import 'package:flutter/material.dart';

enum SupportChannelType { email, phone, chat }

class SupportChannel {
  const SupportChannel({
    required this.type,
    required this.label,
    required this.value,
    required this.icon,
  });

  final SupportChannelType type;
  final String label;
  final String value;
  final IconData icon;
}
