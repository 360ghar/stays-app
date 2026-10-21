import '../../models/wire_enums.dart';

class ProviderAuthResult {
  ProviderAuthResult({this.accessToken, this.refreshToken, this.rawUser});
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? rawUser;
}

/// Outcome of a Google sign-in attempt, which may complete synchronously
/// (native ID-token flow) or asynchronously (OAuth redirect flow — the session
/// arrives later via `onAuthStateChange`).
enum GoogleSignInStatus { session, redirectLaunched, canceled }

class GoogleSignInOutcome {
  const GoogleSignInOutcome(this.status, [this.result]);
  final GoogleSignInStatus status;
  final ProviderAuthResult? result;

  /// Native ID-token flow succeeded with a session.
  bool get hasSession => status == GoogleSignInStatus.session;

  /// Redirect flow launched; routing is finished once the deep-link callback
  /// triggers a `signedIn` auth event.
  bool get isRedirect => status == GoogleSignInStatus.redirectLaunched;

  bool get isCanceled => status == GoogleSignInStatus.canceled;
}

/// Result of the public `POST /api/v1/auth/identifier-status` endpoint.
/// Drives the login state-machine (password vs OTP-first).
class IdentifierStatus {
  const IdentifierStatus({
    required this.exists,
    required this.verified,
    required this.hasPassword,
    this.channel,
    this.nextStep,
  });

  factory IdentifierStatus.fromJson(Map<String, dynamic> json) {
    return IdentifierStatus(
      exists: json['exists'] == true,
      verified: json['verified'] == true,
      hasPassword: json['has_password'] == true,
      // An unknown value reads as null. It is not turned into a real step.
      channel: IdentifierChannel.fromJson(json['channel']),
      nextStep: IdentifierNextStep.fromJson(json['next_step']),
    );
  }

  /// Whether an account already exists for the identifier.
  final bool exists;

  /// Whether the identifier (email/phone) is verified on the account.
  final bool verified;

  /// Whether the account has a password set.
  final bool hasPassword;

  /// Channel detected for the identifier. Null for an unknown value.
  final IdentifierChannel? channel;

  /// The next step the client should take. Null for an unknown value.
  final IdentifierNextStep? nextStep;

  bool get isPasswordStep => nextStep == IdentifierNextStep.password;
  bool get isOtpStep => nextStep == IdentifierNextStep.otp;
  bool get isEmail => channel == IdentifierChannel.email;
  bool get isPhone => channel == IdentifierChannel.phone;
}

/// `GET /api/v1/users/me/auth-state`: where the user is in the sign-in gate.
class AuthGateState {
  const AuthGateState({
    this.stage,
    this.nextAction,
    this.missingFields = const <String>[],
  });

  factory AuthGateState.fromJson(Map<String, dynamic> json) {
    final missing = json['missing_fields'];
    return AuthGateState(
      stage: AuthGateStage.fromJson(json['stage']),
      nextAction: AuthGateAction.fromJson(json['next_action']),
      missingFields: [
        if (missing is List)
          for (final field in missing)
            if (field is String) field,
      ],
    );
  }

  /// Null for an unknown value.
  final AuthGateStage? stage;

  /// Null for an unknown value.
  final AuthGateAction? nextAction;
  final List<String> missingFields;
}

abstract class IAuthProvider {
  Future<ProviderAuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  Future<ProviderAuthResult> loginWithPhone({
    required String phone,
    required String password,
  });

  Future<ProviderAuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
    Map<String, String>? data,
  });

  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  });

  /// Google sign-in. Uses the native ID-token flow when `GOOGLE_WEB_CLIENT_ID`
  /// is configured; otherwise falls back to the Supabase OAuth redirect flow
  /// (the session then arrives asynchronously via `onAuthStateChange`).
  Future<GoogleSignInOutcome> signInWithGoogle();

  /// Native Sign in with Apple (iOS). Returns a session via Supabase
  /// `signInWithIdToken(provider: apple)`. Returns null if the user cancels.
  Future<ProviderAuthResult?> signInWithApple();

  /// Send a 6-digit email OTP (type `email`).
  ///
  /// [shouldCreateUser] must be `false` for login & password-reset sends so an
  /// unknown/mistyped email is NOT silently registered; only signup passes
  /// `true`.
  Future<void> sendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  });

  /// Verify a 6-digit email OTP and establish a session.
  Future<ProviderAuthResult> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Resend a previously requested email OTP. Mirrors [sendEmailOtp]; pass the
  /// same [shouldCreateUser] used for the original send.
  Future<void> resendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  });

  /// Attach a phone number to the current (authenticated) account and trigger
  /// a verification SMS (type `phoneChange`).
  Future<void> addPhone({required String phone});

  /// Verify the phone-change OTP, completing the add-phone flow.
  Future<ProviderAuthResult> verifyPhoneChangeOtp({
    required String phone,
    required String token,
  });

  Future<void> logout();

  Future<Map<String, dynamic>?> getCurrentUserRaw();

  Future<bool> isAuthenticated();
}
