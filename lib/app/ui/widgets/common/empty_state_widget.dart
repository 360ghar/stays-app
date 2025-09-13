import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  const EmptyStateWidget({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
