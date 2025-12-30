import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/payment/controllers/payment_method_controller.dart';

class PaymentMethodsView extends GetView<PaymentMethodController> {
  const PaymentMethodsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.methods.add('Visa •••• 4242'),
        label: const Text('Add Card'),
        icon: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.methods.isEmpty) {
          return const Center(child: Text('No payment methods'));
        }
        return ListView.separated(
          itemCount: controller.methods.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text(controller.methods[i]),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => controller.methods.removeAt(i),
            ),
          ),
        );
      }),
    );
  }
}
