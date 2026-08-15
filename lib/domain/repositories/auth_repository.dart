import 'package:mesa/domain/models/auth_user.dart';

/// Authentication, as the rest of the app sees it (F1).
///
/// Every method throws [AuthFailure] on failure rather than returning a result
/// type, so callers can wrap a whole flow in one `try`/`catch`.
abstract interface class AuthRepository {
  /// Emits the current identity, and `null` once signed out.
  ///
  /// The stream does not emit until the provider has restored any persisted
  /// session, which is what lets the router show a splash instead of flashing
  /// the sign-in screen on cold start.
  Stream<AuthUser?> authStateChanges();

  /// The identity right now, without waiting on the stream. `null` when signed
  /// out or not yet restored.
  AuthUser? get currentUser;

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Throws [AuthFailure] with [AuthFailureKind.cancelled] if the user
  /// dismisses the account picker.
  Future<AuthUser> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  /// Signs out and clears the local Firestore cache (F1).
  ///
  /// Implementations must not be called while Firestore listeners are still
  /// attached — see the implementation for why the ordering matters.
  Future<void> signOut();
}
