import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/payment/controllers/payment_controller.dart';

/// Full payment screen. Expects booking context via [Get.arguments]:
///   - `booking_id` (int, required)
///   - `amount` (double, required)
///   - `currency` (String, default INR)
///   - `title` (String?) - property/booking title
///   - `email`, `phone`, `name` (String?) - prefill helpers
class PaymentView extends StatelessWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();
    final args = (Get.arguments is Map)
        ? Get.arguments as Map
        : <String, dynamic>{};
    final bookingId = (args['booking_id'] as num?)?.toInt() ?? 0;
    final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = (args['currency'] as String?) ?? 'INR';
    final title = args['title'] as String? ?? 'Booking';
    final email = args['email'] as String?;
    final phone = args['phone'] as String?;
    final name = args['name'] as String?;

    // Configure once if not already set.
    if (controller.bookingId.value != bookingId ||
        controller.amount.value != amount) {
      controller.configure(
        bookingId: bookingId,
        amount: amount,
        currency: currency,
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Obx(() {
        if (controller.isProcessing.value || controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: colors.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Booking #$bookingId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount due'),
                          Text(
                            '$currency ${amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: amount <= 0
                    ? null
                    : () => controller.processPayment(
                        name: name,
                        email: email,
                        phone: phone,
                      ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Pay Securely'),
              ),
              const SizedBox(height: 12),
              Text(
                'Payments are secured by Razorpay. UPI, cards, netbanking and wallets supported.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
