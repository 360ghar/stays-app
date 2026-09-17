import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/features/listing/providers/search_providers.dart';

/// V2 search. Debounced place autocomplete → results at coordinates.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openResults(double lat, double lng) async {
    await context.push(AppPaths.searchResults, extra: {'lat': lat, 'lng': lng});
  }

  Future<void> _useMyLocation() async {
    if (!Get.isRegistered<LocationService>()) return;
    final location = Get.find<LocationService>();
    try {
      await location.updateLocation(ensurePrecise: true);
    } catch (_) {
      // Fall through to whatever coordinates are available.
    }
    final lat = location.latitude;
    final lng = location.longitude;
    if (lat == null || lng == null || !mounted) return;
    await _openResults(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: notifier.onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Search by city or area',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          if (state.isSearching) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(
              Icons.my_location,
              color: StayTokens.accentDark,
            ),
            title: const Text('Use my location', style: StayTokens.body),
            onTap: _useMyLocation,
          ),
          const Divider(height: 1),
          Expanded(
            child: state.predictions.isEmpty && !state.isSearching
                ? const Center(
                    child: Text(
                      'Try "Goa", "Jaipur", "Whitefield"…',
                      style: StayTokens.bodySecondary,
                    ),
                  )
                : ListView.separated(
                    itemCount: state.predictions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, i) {
                      final prediction = state.predictions[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.place_outlined,
                          color: StayTokens.inkSecondary,
                        ),
                        title: Text(
                          prediction.description,
                          style: StayTokens.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          final details = await notifier.selectPrediction(
                            prediction,
                          );
                          if (details == null || !context.mounted) return;
                          await _openResults(details.lat, details.lng);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
