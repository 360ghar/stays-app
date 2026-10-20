import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase auth state as Riverpod. Source of truth for go_router redirect.
///
/// A session with a non-empty access token means authenticated.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  return session != null && session.accessToken.isNotEmpty;
});

/// Id of the signed-in user, or null when signed out.
///
/// Every provider that holds one account's data watches it in `build()`, so
/// it resets on sign-out and on every change of user. A token refresh keeps
/// the id and resets nothing.
final accountIdProvider = Provider<String?>((ref) {
  try {
    // Rebuilds on each auth event. Listeners hear of it only when the id
    // changes.
    ref.watch(authStateProvider);
    return ref.watch(supabaseClientProvider).auth.currentUser?.id;
  } catch (_) {
    // Supabase is not initialised (unit tests): nobody is signed in.
    return null;
  }
});

/// For a notifier that holds one account's data. Call [watchAccount] first in
/// `build()`. A method that awaits a request takes an [accountGuard] before the
/// request and drops the result when the guard is false: the request belongs to
/// an account that signed out.
mixin AccountBound<S> on Notifier<S> {
  String? watchAccount() => ref.watch(accountIdProvider);

  bool Function() accountGuard() {
    final account = ref.read(accountIdProvider);
    return () => ref.read(accountIdProvider) == account;
  }
}
