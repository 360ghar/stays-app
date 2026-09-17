import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase auth state as Riverpod. Source of truth for go_router redirect.
///
/// Mirrors the legacy [AuthMiddleware] check: a session with a non-empty
/// access token means authenticated.
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
