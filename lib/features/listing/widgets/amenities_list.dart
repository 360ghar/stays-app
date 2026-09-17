import 'package:flutter/material.dart';

import 'package:stays_app/core/theme/tokens.dart';

/// Amenities grid. Pure widget shared by legacy detail and v2 detail.
class AmenitiesList extends StatelessWidget {
  const AmenitiesList({required this.amenities, super.key});
  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amenities', style: StayTokens.title),
        const SizedBox(height: StayTokens.s12),
        Wrap(
          spacing: StayTokens.s8,
          runSpacing: StayTokens.s8,
          children: [
            for (final amenity in amenities)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: StayTokens.s12,
                  vertical: StayTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: StayTokens.paperWarm,
                  borderRadius: BorderRadius.circular(StayTokens.radiusPill),
                  border: Border.all(color: StayTokens.line),
                ),
                child: Text(amenity, style: StayTokens.body),
              ),
          ],
        ),
      ],
    );
  }
}
