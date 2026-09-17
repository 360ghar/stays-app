import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/payment/providers/payment_methods_providers.dart';

/// V2 saved payment methods. List + remove. New methods save at checkout.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentMethodsProvider);
    final notifier = ref.read(paymentMethodsProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Payment methods')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.methods.isEmpty) {
            return const AsyncState.loading(message: 'Loading methods…');
          }
          if (state.error.isNotEmpty && state.methods.isEmpty) {
            return AsyncState.error(state.error, onRetry: notifier.load);
          }
          if (state.methods.isEmpty) {
            return const AsyncState.empty(
              message:
                  'No saved methods yet. New cards save automatically at checkout.',
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(StayTokens.s16),
              itemCount: state.methods.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: StayTokens.s12),
              itemBuilder: (context, i) {
                final method = state.methods[i];
                return Container(
                  padding: const EdgeInsets.all(StayTokens.s16),
                  decoration: BoxDecoration(
                    border: Border.all(color: StayTokens.line),
                    borderRadius: BorderRadius.circular(StayTokens.radiusCard),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.credit_card_outlined,
                        color: StayTokens.inkSecondary,
                      ),
                      const SizedBox(width: StayTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.displayName,
                              style: StayTokens.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (method.nickname?.isNotEmpty == true)
                              Text(method.nickname!, style: StayTokens.label),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => notifier.remove(method.id),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
