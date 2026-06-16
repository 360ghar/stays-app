class ProviderAuthResult {
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? rawUser;
  ProviderAuthResult({this.accessToken, this.refreshToken, this.rawUser});
}

/// Outcome of a Google sign-in attempt, which may complete synchronously
/// (native ID-token flow) or asynchronously (OAuth redirect flow — the session
/// arrives later via `onAuthStateChange`).
enum GoogleSignInStatus { session, redirectLaunched, canceled }

class GoogleSignInOutcome {
  final GoogleSignInStatus status;
  final ProviderAuthResult? result;

  const GoogleSignInOutcome(this.status, [this.result]);

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
    required this.channel,
    required this.nextStep,
  });

  factory IdentifierStatus.fromJson(Map<String, dynamic> json) {
    return IdentifierStatus(
      exists: json['exists'] == true,
      verified: json['verified'] == true,
      hasPassword: json['has_password'] == true,
      channel: (json['channel'] as String?) ?? 'email',
      nextStep: (json['next_step'] as String?) ?? 'otp',
    );
  }

  /// Whether an account already exists for the identifier.
  final bool exists;

  /// Whether the identifier (email/phone) is verified on the account.
  final bool verified;

  /// Whether the account has a password set.
  final bool hasPassword;

  /// "email" or "phone" — channel detected for the identifier.
  final String channel;

  /// "password" or "otp" — the next step the client should take.
  final String nextStep;

  bool get isPasswordStep => nextStep == 'password';
  bool get isOtpStep => nextStep == 'otp';
  bool get isEmail => channel == 'email';
  bool get isPhone => channel == 'phone';
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
