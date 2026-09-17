import 'package:flutter/material.dart';

import 'package:stays_app/core/theme/tokens.dart';

/// One loading / error / empty pattern for every rebuilt screen.
///
/// Canonical async-state widget for V2 screens (Riverpod + go_router).
/// Legacy GetX screens use [AsyncStateBuilder] in
/// `lib/app/ui/widgets/common/async_state_builder.dart`, which is deprecated;
/// do not use it in new V2 code.
///
/// Replaces scattered spinners and bare Text errors in legacy views.
class AsyncState extends StatelessWidget {
  const AsyncState.loading({super.key, this.message})
    : _kind = _Kind.loading,
      error = null,
      onRetry = null;

  const AsyncState.error(this.error, {super.key, this.onRetry})
    : _kind = _Kind.error,
      message = null;

  const AsyncState.empty({super.key, this.message = 'Nothing here yet.'})
    : _kind = _Kind.empty,
      error = null,
      onRetry = null;
  final _Kind _kind;
  final String? message;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (_kind) {
      case _Kind.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: StayTokens.s12),
                Text(message!, style: StayTokens.bodySecondary),
              ],
            ],
          ),
        );
      case _Kind.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(StayTokens.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: StayTokens.s12),
                Text(
                  error ?? 'Something went wrong.',
                  style: StayTokens.body,
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: StayTokens.s16),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ],
            ),
          ),
        );
      case _Kind.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(StayTokens.s24),
            child: Text(
              message!,
              style: StayTokens.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}

enum _Kind { loading, error, empty }
