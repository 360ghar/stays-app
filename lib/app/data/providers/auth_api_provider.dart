import '../../utils/logger/app_logger.dart';
import 'auth/i_auth_provider.dart';
import 'base_provider.dart';

/// Thin client for the backend auth state-machine endpoints.
///
/// Backend contract (FROZEN):
/// - POST /api/v1/auth/identifier-status (PUBLIC):
///     req {identifier}; res {exists, verified, has_password, channel, next_step}
/// - POST /api/v1/auth/last-method (AUTH):
///     req {method}; res 204
class AuthApiProvider extends BaseProvider {
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

  /// Records the last-used auth method for the authenticated user.
  /// Best-effort: failures are logged and swallowed so they never block login.
  Future<void> recordLastMethod(String method) async {
    try {
      final response = await post('/api/v1/auth/last-method', {
        'method': method,
      });
      // 204 No Content is success.
      handleResponse(response, (_) => null);
    } catch (e) {
      AppLogger.warning('Failed to record last auth method "$method": $e');
    }
  }

  /// Fetches the auth gate state from the backend.
  /// Returns a map with `stage`, `next_action`, and `missing_fields`.
  Future<Map<String, dynamic>> getAuthGateState({String app = 'stays'}) async {
    final response = await get('/api/v1/users/me/auth-state?app=$app');
    return handleResponse(
      response,
      (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Marks the given app's onboarding as complete (sets
  /// `<app>_onboarding_completed = true` on the user). Best-effort: failures
  /// are logged and swallowed so they never block entry to the app.
  Future<void> completeOnboarding({String app = 'stays'}) async {
    try {
      final response = await post('/api/v1/users/me/onboarding?app=$app', {});
      handleResponse(response, (_) => null);
    } catch (e) {
      AppLogger.warning('Failed to mark onboarding complete (app=$app): $e');
    }
  }

  /// Permanently deletes the authenticated user's account.
  /// Backend hard-deletes the Supabase Auth user and anonymizes the local row.
  Future<void> deleteAccount() async {
    final response = await post('/api/v1/auth/delete-account', {});
    handleResponse(response, (_) => null);
  }
}
