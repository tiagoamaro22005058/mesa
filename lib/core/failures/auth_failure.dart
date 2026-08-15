/// The ways authentication can fail, as the app understands them.
///
/// Deliberately provider-agnostic: `firebase_auth`'s error codes are mapped
/// onto this in the data layer, so nothing above it needs to know which
/// backend is in use. Each kind maps to exactly one user-facing string.
enum AuthFailureKind {
  /// Wrong password, or an email/password pair that does not match.
  invalidCredentials,

  /// Sign-up against an address that already has an account.
  emailInUse,

  /// The password does not meet the provider's minimum strength.
  weakPassword,

  /// The address is not a well-formed email.
  invalidEmail,

  /// No account exists for this address.
  userNotFound,

  /// The account exists but has been disabled.
  userDisabled,

  /// No connectivity. Sign-in and sign-up are the only features NFR1 allows to
  /// fail this way.
  networkUnavailable,

  /// Rate limited after too many attempts.
  tooManyRequests,

  /// The user backed out of the Google sign-in sheet. Not an error worth
  /// showing — the UI stays silent on this one.
  cancelled,

  /// Anything unmapped. Carries the original code so a real failure is still
  /// diagnosable from a bug report.
  unknown,
}

/// A failure raised by [AuthRepository] implementations.
///
/// Thrown rather than returned so callers can use ordinary `try`/`catch`
/// around the provider calls; the auth controllers turn it into an
/// `AsyncError` for the UI to render.
final class AuthFailure implements Exception {
  const AuthFailure(this.kind, {this.code});

  final AuthFailureKind kind;

  /// The provider's original error code, retained only for [AuthFailureKind.unknown].
  final String? code;

  @override
  String toString() =>
      code == null ? 'AuthFailure(${kind.name})' : 'AuthFailure(${kind.name}, code: $code)';

  @override
  bool operator ==(Object other) =>
      other is AuthFailure && other.kind == kind && other.code == code;

  @override
  int get hashCode => Object.hash(kind, code);
}
