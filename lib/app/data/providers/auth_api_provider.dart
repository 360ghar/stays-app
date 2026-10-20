import '../../utils/logger/app_logger.dart';
import '../models/wire_enums.dart';
import 'auth/i_auth_provider.dart';
import 'base_provider.dart';

/// Thin client for the backend auth state-machine endpoints.
///
/// Backend contract:
/// - POST /api/v1/auth/identifier-status (PUBLIC):
///     req {identifier}; res {exists, verified, has_password, channel, next_step}
/// - GET /api/v1/users/me/auth-state?app= (AUTH): res {stage, next_action, missing_fields}
/// - POST /api/v1/users/me/onboarding?app= (AUTH): res the user
/// - DELETE /api/v1/users/me (AUTH): res 204
class AuthApiProvider extends BaseProvider {
  AuthApiProvider({super.dio});

  /// Calls the public identifier-status endpoint. Throws on transport errors.
  Future<IdentifierStatus> identifierStatus(String identifier) async {
    final response = await post('/api/v1/auth/identifier-status', {
      'identifier': identifier,
    });
    return handleResponse(
      response,
      (json) => IdentifierStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches the auth gate state from the backend.
  Future<AuthGateState> getAuthGateState({AppKey app = AppKey.stays}) async {
    final response = await get(
      '/api/v1/users/me/auth-state',
      query: {'app': app.wire},
    );
    return handleResponse(
      response,
      (json) => AuthGateState.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  /// Marks the given app's onboarding as complete (sets
  /// `<app>_onboarding_completed = true` on the user). Best-effort: failures
  /// are logged and swallowed so they never block entry to the app.
  /// Returns true on success, false when the write failed (caller decides).
  Future<bool> completeOnboarding({AppKey app = AppKey.stays}) async {
    try {
      final response = await post(
        '/api/v1/users/me/onboarding',
        null,
        query: {'app': app.wire},
      );
      handleResponse(response, (_) => null);
      return true;
    } catch (e) {
      AppLogger.warning(
        'Failed to mark onboarding complete (app=${app.wire}): $e',
      );
      return false;
    }
  }

  /// Permanently deletes the authenticated user's account
  /// (`DELETE /api/v1/users/me`, 204 with no body).
  /// Backend hard-deletes the Supabase Auth user and anonymizes the local row.
  Future<void> deleteAccount() async {
    final response = await delete('/api/v1/users/me');
    handleResponse(response, (_) => null);
  }
}
