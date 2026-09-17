import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/features/payment/providers/payment_providers.dart';

/// V2 payment. Order → Razorpay checkout → verify → trips.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, this.bookingId = 0, this.amount = 0});
  final int bookingId;
  final double amount;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bookingId <= 0 || widget.amount <= 0) return;
      ref
          .read(paymentProvider.notifier)
          .configure(bookingId: widget.bookingId, amount: widget.amount);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingId <= 0 || widget.amount <= 0) {
      AppLogger.warning(
        'payment: PaymentScreen reached with invalid '
        'bookingId=${widget.bookingId} amount=${widget.amount}; '
        'showing error instead of silently charging 0.',
        {'bookingId': widget.bookingId, 'amount': widget.amount},
      );
      return const RouteErrorScreen(
        message: 'Missing payment details. Please retry from your trips.',
        recoveryLabel: 'Back to trips',
        recoveryLocation: AppPaths.trips,
      );
    }
    final state = ref.watch(paymentProvider);
    ref.listen(paymentProvider, (_, next) {
      if (next.status == PaymentStatus.success) {
        _snack(next.message);
        context.go(AppPaths.trips);
      } else if (next.status == PaymentStatus.failed) {
        _snack(next.message);
      } else if (next.status == PaymentStatus.cancelled) {
        _snack(next.message);
      }
    });
    final processing = state.status == PaymentStatus.processing;
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(StayTokens.s16),
        children: [
          Container(
            padding: const EdgeInsets.all(StayTokens.s16),
            decoration: BoxDecoration(
              color: StayTokens.paperWarm,
              borderRadius: BorderRadius.circular(StayTokens.radiusCard),
              border: Border.all(color: StayTokens.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount due', style: StayTokens.label),
                Text(
                  '₹${state.amount.toStringAsFixed(0)}',
                  style: StayTokens.titleLarge,
                ),
                Text(
                  'Booking #${state.bookingId}',
                  style: StayTokens.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: StayTokens.s16),
          const Text('Pay securely with Razorpay', style: StayTokens.body),
          const SizedBox(height: StayTokens.s24),
          FilledButton(
            onPressed: processing
                ? null
                : () => ref.read(paymentProvider.notifier).process(),
            child: processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Pay ₹${state.amount.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
  }
}
