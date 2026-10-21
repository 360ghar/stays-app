import 'package:flutter/material.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/core/theme/tokens.dart';

/// Primary facts row: bedrooms, baths, guests, size. Pure widget.
class DetailFacts extends StatelessWidget {
  const DetailFacts({required this.property, super.key});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (property.bedrooms != null)
        (Icons.bed_outlined, '${property.bedrooms} bed'),
      if (property.bathrooms != null)
        (Icons.bathtub_outlined, '${property.bathrooms} bath'),
      if (property.maxGuests != null)
        (Icons.people_outline, '${property.maxGuests} guests'),
      if (property.squareFeet != null)
        (Icons.square_foot, '${property.squareFeet!.toStringAsFixed(0)} sqft'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: StayTokens.s16,
      runSpacing: StayTokens.s8,
      children: [
        for (final fact in facts)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fact.$1, size: 18, color: StayTokens.inkSecondary),
              const SizedBox(width: StayTokens.s4),
              Text(fact.$2, style: StayTokens.bodySecondary),
            ],
          ),
      ],
    );
  }
}
