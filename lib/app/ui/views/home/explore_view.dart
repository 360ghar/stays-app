import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              key: const Key('search_field'),
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Where are you going?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => Get.toNamed(Routes.searchResults, parameters: {
                    'q': controller.text.trim(),
                  }),
                ),
              ),
              onSubmitted: (_) => Get.toNamed(Routes.searchResults, parameters: {
                'q': controller.text.trim(),
              }),
            ),
            const SizedBox(height: 24),
            const Text('Popular destinations'),
          ],
        ),
      ),
    );
  }
}
