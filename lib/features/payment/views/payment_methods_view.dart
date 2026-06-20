import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/payment/controllers/payment_method_controller.dart';

class PaymentMethodsView extends GetView<PaymentMethodController> {
  const PaymentMethodsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        label: const Text('Add Card'),
        icon: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.methods.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.methods.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: 64,
                  color: colors.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No payment methods yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a card or UPI to pay faster next time.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.methods.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final m = controller.methods[i];
            return ListTile(
              leading: Icon(_iconFor(m.methodType), color: colors.primary),
              title: Text(m.displayName),
              subtitle: m.nickname == null
                  ? null
                  : Text(m.nickname!, style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.removeMethod(m.id),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return Icons.account_balance_wallet_outlined;
      case 'netbanking':
        return Icons.account_balance_outlined;
      default:
        return Icons.credit_card;
    }
  }

  void _showAddSheet(BuildContext context) {
    final brandCtrl = TextEditingController();
    final last4Ctrl = TextEditingController();
    final nicknameCtrl = TextEditingController();
    String methodType = 'card';
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Card'),
                        selected: methodType == 'card',
                        onSelected: (_) => setState(() => methodType = 'card'),
                      ),
                      ChoiceChip(
                        label: const Text('UPI'),
                        selected: methodType == 'upi',
                        onSelected: (_) => setState(() => methodType = 'upi'),
                      ),
                      ChoiceChip(
                        label: const Text('Netbanking'),
                        selected: methodType == 'netbanking',
                        onSelected: (_) =>
                            setState(() => methodType = 'netbanking'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (methodType == 'card') ...[
                    TextFormField(
                      controller: brandCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Brand (e.g. Visa)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: last4Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Last 4 digits',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (v) => (v == null || v.length != 4)
                          ? 'Enter 4 digits'
                          : null,
                    ),
                  ],
                  TextFormField(
                    controller: nicknameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nickname (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (methodType == 'card' &&
                          !(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Get.back();
                      await Get.find<PaymentMethodController>().addMethod(
                        methodType: methodType,
                        brand: brandCtrl.text.trim().isEmpty
                            ? null
                            : brandCtrl.text.trim(),
                        last4: last4Ctrl.text.trim().isEmpty
                            ? null
                            : last4Ctrl.text.trim(),
                        nickname: nicknameCtrl.text.trim().isEmpty
                            ? null
                            : nicknameCtrl.text.trim(),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}
