import 'package:flutter/material.dart';

import 'package:stays_app/core/theme/tokens.dart';

/// Host card. Pure widget shared by legacy detail and v2 detail.
class HostCard extends StatelessWidget {
  const HostCard({required this.hostName, super.key, this.onContact});
  final String hostName;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final initial = hostName.isNotEmpty ? hostName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(StayTokens.s16),
      decoration: BoxDecoration(
        color: StayTokens.paper,
        borderRadius: BorderRadius.circular(StayTokens.radiusCard),
        border: Border.all(color: StayTokens.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: StayTokens.paperWarm,
            child: Text(initial, style: StayTokens.title),
          ),
          const SizedBox(width: StayTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hostName,
                  style: StayTokens.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Host', style: StayTokens.label),
              ],
            ),
          ),
          if (onContact != null)
            OutlinedButton(onPressed: onContact, child: const Text('Contact')),
        ],
      ),
    );
  }
}
