import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesa/core/failures/auth_failure.dart';

/// Translates provider errors into [AuthFailure].
///
/// Isolated from the repository so every branch can be unit-tested without a
/// Firebase instance (§11).
abstract final class AuthFailureMapper {
  /// Maps a [FirebaseAuthException] error code onto an [AuthFailure].
  ///
  /// Note that with email-enumeration protection enabled — the Firebase
  /// default for new projects — a wrong password and an unknown address both
  /// arrive as `invalid-credential`, so the UI must not claim to know which.
  static AuthFailure fromFirebase(FirebaseAuthException exception) {
    final kind = switch (exception.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'invalid-login-credentials' => AuthFailureKind.invalidCredentials,
      'email-already-in-use' => AuthFailureKind.emailInUse,
      'weak-password' => AuthFailureKind.weakPassword,
      'invalid-email' => AuthFailureKind.invalidEmail,
      'user-not-found' => AuthFailureKind.userNotFound,
      'user-disabled' => AuthFailureKind.userDisabled,
      'network-request-failed' => AuthFailureKind.networkUnavailable,
      'too-many-requests' => AuthFailureKind.tooManyRequests,
      _ => AuthFailureKind.unknown,
    };

    return kind == AuthFailureKind.unknown
        ? AuthFailure(kind, code: exception.code)
        : AuthFailure(kind);
  }

  /// Maps a [GoogleSignInException] onto an [AuthFailure].
  static AuthFailure fromGoogle(GoogleSignInException exception) {
    final kind = switch (exception.code) {
      GoogleSignInExceptionCode.canceled => AuthFailureKind.cancelled,
      GoogleSignInExceptionCode.interrupted => AuthFailureKind.networkUnavailable,
      _ => AuthFailureKind.unknown,
    };

    return kind == AuthFailureKind.unknown
        ? AuthFailure(kind, code: exception.code.name)
        : AuthFailure(kind);
  }
}
