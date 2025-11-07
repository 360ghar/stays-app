import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/listing/location_search_controller.dart';

class LocationSearchView extends GetView<LocationSearchController> {
  const LocationSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: controller.textController,
              decoration: InputDecoration(
                hintText: 'Search by area, landmark, address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.textController.clear();
                            controller.onQueryChanged('');
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: controller.onQueryChanged,
              autofocus: true,
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.predictions.isEmpty) {
                return const Center(child: Text('Search a location to begin'));
              }
              return ListView.separated(
                itemCount: controller.predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = controller.predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(p.description),
                    onTap: () => controller.selectPrediction(p),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
