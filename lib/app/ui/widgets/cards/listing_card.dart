import 'package:flutter/material.dart';

import '../../../data/models/listing_model.dart';
import '../../../utils/helpers/currency_helper.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: listing.primaryImage.isNotEmpty
                ? Image.network(listing.primaryImage, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300, child: const Icon(Icons.home, size: 48)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.star_rate_rounded, size: 18),
                    Text(listing.rating.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  listing.location.city,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text('${CurrencyHelper.format(listing.pricePerNight)} · per night'),
              ],
            ),
          )
        ],
      ),
    );
  }
}
